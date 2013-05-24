module Killbill::Litle
  class PaymentPlugin < Killbill::Plugin::Payment
    def start_plugin
      Killbill::Litle.initialize! @logger, @conf_dir
      @gateway = Killbill::Litle.gateway

      super

      @logger.info "Killbill::Litle::PaymentPlugin started"
    end

    # return DB connections to the Pool if required
    def after_request
      ActiveRecord::Base.connection.close
    end

    def process_payment(kb_account_id, kb_payment_id, kb_payment_method_id, amount_in_cents, currency, call_context, options = {})
      # If the payment was already made, just return the status
      # TODO Should we set the Litle Id field to check for dups (https://www.litle.com/mc-secure/DupeChecking_V1.2.pdf)?
      litle_transaction = LitleTransaction.from_kb_payment_id(kb_payment_id) rescue nil
      return litle_transaction.litle_response.to_payment_response unless litle_transaction.nil?

      # Required argument
      # Note! The field is limited to 25 chars, so we convert the UUID (in hex) to base64
      options[:order_id] ||= Utils.compact_uuid kb_payment_id

      # Set a default report group
      options[:merchant] ||= report_group_for_currency(currency)
      # Retrieve the Litle token
      token = get_token(kb_payment_method_id)

      # Go to Litle
      litle_response = @gateway.purchase amount_in_cents, ActiveMerchant::Billing::LitleGateway::LitleCardToken.new(:token => token), options
      response = save_response_and_transaction litle_response, :charge, kb_payment_id, amount_in_cents

      response.to_payment_response
    end

    def process_refund(kb_account_id, kb_payment_id, amount_in_cents, currency, call_context, options = {})
      litle_transaction = LitleTransaction.find_candidate_transaction_for_refund(kb_payment_id, amount_in_cents)

      # Set a default report group
      options[:merchant] ||= report_group_for_currency(currency)

      # Go to Litle
      litle_response = @gateway.credit amount_in_cents, litle_transaction.litle_txn_id, options
      response = save_response_and_transaction litle_response, :refund, kb_payment_id, amount_in_cents

      response.to_refund_response
    end

    def get_payment_info(kb_account_id, kb_payment_id, tenant_context, options = {})
      # We assume the payment is immutable in Litle and only look at our tables since there
      # doesn't seem to be a Litle API to fetch details for a given transaction.
      # TODO How can we support Authorization/Sale Recycling?
      litle_transaction = LitleTransaction.from_kb_payment_id(kb_payment_id)

      litle_transaction.litle_response.to_payment_response
    end

    def add_payment_method(kb_account_id, kb_payment_method_id, payment_method_props, set_default, call_context, options = {})
      # Set a default report group
      options[:merchant] ||= report_group_for_account(kb_account_id)

      # TODO Add support for real credit cards
      token = (payment_method_props.properties.find { |kv| kv.key == 'paypageRegistrationId' }).value
      litle_response = @gateway.store token, options
      response = save_response_and_transaction litle_response, :add_payment_method

      if response.success
        LitlePaymentMethod.create :kb_account_id => kb_account_id, :kb_payment_method_id => kb_payment_method_id, :litle_token => response.litle_token
      else
        raise response.message
      end
    end

    def delete_payment_method(kb_account_id, kb_payment_method_id, call_context, options = {})
      LitlePaymentMethod.mark_as_deleted! kb_payment_method_id
    end

    def get_payment_method_detail(kb_account_id, kb_payment_method_id, tenant_context, options = {})
      LitlePaymentMethod.from_kb_payment_method_id(kb_payment_method_id).to_payment_method_response
    end

    def get_payment_methods(kb_account_id, refresh_from_gateway, call_context, options = {})
      LitlePaymentMethod.from_kb_account_id(kb_account_id).collect { |pm| pm.to_payment_method_response }
    end

    private

    def report_group_for_account(kb_account_id)
      account = @kb_apis.get_account_by_id(kb_account_id)
      currency = account.currency
      report_group_for_currency(currency)
    rescue Killbill::Plugin::JKillbillApi::APINotAvailableError
      "Default Report Group"
    end

    def report_group_for_currency(currency)
      "Report Group for #{currency}"
    end

    def get_token(kb_payment_method_id)
      LitlePaymentMethod.from_kb_payment_method_id(kb_payment_method_id).litle_token
    end

    def save_response_and_transaction(litle_response, api_call, kb_payment_id=nil, amount_in_cents=0)
      @logger.warn "Unsuccessful #{api_call}: #{litle_response.message}" unless litle_response.success?

      # Save the response to our logs
      response = LitleResponse.from_response(api_call, kb_payment_id, litle_response)
      response.save!

      if response.success and !kb_payment_id.blank? and !response.litle_txn_id.blank?
        # Record the transaction
        transaction = response.create_litle_transaction!(:amount_in_cents => amount_in_cents, :api_call => api_call, :kb_payment_id => kb_payment_id, :litle_txn_id => response.litle_txn_id)
        @logger.debug "Recorded transaction: #{transaction.inspect}"
      end
      response
    end
  end
end
