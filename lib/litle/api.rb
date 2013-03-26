module Killbill::Litle
  class PaymentPlugin < Killbill::Plugin::Payment
    def start_plugin
      Killbill::Litle.initialize! "#{@root}/litle.yml", @logger
      @gateway = Killbill::Litle.gateway

      super

      @logger.info "Killbill::Litle::PaymentPlugin started"
    end

    def get_name
      'litle'
    end

    def process_charge(kb_account_id, kb_payment_id, kb_payment_method_id, amount_in_cents, currency, options = {})
      # Required argument
      # Note! The field is limited to 25 chars, so we convert the UUID (in hex) to base64
      options[:order_id] ||= Utils.compact_uuid kb_payment_id

      # Set a default report group
      options[:merchant] ||= report_group_for_payment_method(kb_payment_method_id)

      # Retrieve the Litle token
      token = get_token(kb_payment_method_id)

      # Go to Litle
      litle_response = @gateway.purchase amount_in_cents, token, options
      response = save_response_and_transaction litle_response, :charge, kb_payment_id, amount_in_cents

      response.to_payment_response
    end

    def process_refund(kb_account_id, kb_payment_id, amount_in_cents, currency, options = {})
      # Find one successful charge which amount is at least the amount we are trying to refund
      litle_transaction = LitleTransaction.where("litle_transactions.amount_in_cents >= ?", amount_in_cents).find_last_by_api_call_and_kb_payment_id(:charge, kb_payment_id)
      raise "Unable to find Litle transaction id for payment #{kb_payment_id}" if litle_transaction.nil?

      # Set a default report group
      options[:merchant] ||= report_group_for_payment(kb_payment_id)

      # Go to Litle
      litle_response = @gateway.credit amount_in_cents, litle_transaction.litle_txn_id, options
      response = save_response_and_transaction litle_response, :refund, kb_payment_id, amount_in_cents

      response.to_refund_response
    end

    def get_payment_info(kb_account_id, kb_payment_id, options = {})
      # We assume the payment is immutable in Litle and only look at our tables since there
      # doesn't seem to be a Litle API to fetch details for a given transaction.
      # TODO How can we support Authorization/Sale Recycling?
      litle_transaction = LitleTransaction.from_kb_payment_id(kb_payment_id)

      litle_transaction.litle_response.to_payment_response
    end

    def add_payment_method(kb_account_id, kb_payment_method_id, payment_method_props, set_default, options = {})
      # Set a default report group
      options[:merchant] ||= report_group_for_account(kb_account_id)

      cc = ActiveMerchant::Billing::CreditCard.new(:number => payment_method_props.value_string('number'), :description => kb_payment_method_id)
      litle_response = @gateway.store cc, options
      response = save_response_and_transaction litle_response, :add_payment_method

      LitlePaymentMethod.create :kb_account_id => kb_account_id, :kb_payment_method_id => kb_payment_method_id, :litle_token => response.litle_token
    end

    def delete_payment_method(kb_account_id, kb_payment_method_id, options = {})
      LitlePaymentMethod.mark_as_deleted! kb_payment_method_id
    end

    def get_payment_method_detail(kb_account_id, kb_payment_method_id, options = {})
      LitlePaymentMethod.from_kb_payment_method_id(kb_payment_method_id).to_payment_method_response
    end

    def get_payment_methods(kb_account_id, refresh_from_gateway = false, options = {})
      LitlePaymentMethod.from_kb_account_id(kb_account_id).collect { |pm| pm.to_payment_method_response }
    end

    private

    def report_group_for_payment(kb_payment_id)
      payment = payment_api.get_payment(kb_payment_method_id, nil)
      report_group_for_account payment.get_account_id
    rescue APINotAvailableError
      "Default Report Group"
    end

    def report_group_for_payment_method(kb_payment_method_id)
      payment_method = payment_api.get_payment_method_by_id(kb_payment_method_id, false, nil)
      report_group_for_account payment_method.get_account_id
    rescue APINotAvailableError
      "Default Report Group"
    end

    def report_group_for_account(kb_account_id)
      account = account_user_api.get_account_by_id(kb_account_id)
      currency = account.get_currency
      "Report Group for #{currency}"
    rescue APINotAvailableError
      "Default Report Group"
    end

    def get_token(kb_payment_method_id)
      LitlePaymentMethod.from_kb_payment_method_id(kb_payment_method_id).litle_token
    end

    def save_response_and_transaction(litle_response, api_call, kb_payment_id=nil, amount_in_cents=0)
      @logger.warn "Unsuccessful #{api_call}: #{litle_response.message}" unless litle_response.success?

      # Save the response to our logs
      response = LitleResponse.from_response(api_call, kb_payment_id, litle_response)
      response.save!

      if response.success and !response.litle_txn_id.blank?
        # Record the transaction
        transaction = response.create_litle_transaction!(:amount_in_cents => amount_in_cents, :api_call => api_call, :kb_payment_id => kb_payment_id, :litle_txn_id => response.litle_txn_id)
        @logger.debug "Recorded transaction: #{transaction.inspect}"
      end
      response
    end
  end
end
