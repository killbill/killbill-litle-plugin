module Killbill::Litle
  class PaymentPlugin < Killbill::Plugin::Payment
    def start_plugin
      Killbill::Litle.initialize! @logger, @conf_dir, @kb_apis

      super

      @logger.info 'Killbill::Litle::PaymentPlugin started'
    end

    # return DB connections to the Pool if required
    def after_request
      ActiveRecord::Base.connection.close
    end

    def process_payment(kb_account_id, kb_payment_id, kb_payment_method_id, amount, currency, call_context = nil, options = {})
      amount_in_cents = (amount * 100).to_i

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
      gateway = Killbill::Litle.gateway_for_currency(currency)
      litle_response = gateway.purchase amount_in_cents, ActiveMerchant::Billing::LitleGateway::LitleCardToken.new(:token => token), options
      response = save_response_and_transaction litle_response, :charge, kb_payment_id, amount_in_cents

      response.to_payment_response
    end

    def get_payment_info(kb_account_id, kb_payment_id, tenant_context = nil, options = {})
      # We assume the payment is immutable in Litle and only look at our tables since there
      # doesn't seem to be a Litle API to fetch details for a given transaction.
      # TODO How can we support Authorization/Sale Recycling?
      litle_transaction = LitleTransaction.from_kb_payment_id(kb_payment_id)

      litle_transaction.litle_response.to_payment_response
    end

    def process_refund(kb_account_id, kb_payment_id, amount, currency, call_context = nil, options = {})
      amount_in_cents = (amount * 100).to_i

      litle_transaction = LitleTransaction.find_candidate_transaction_for_refund(kb_payment_id, amount_in_cents)

      # Set a default report group
      options[:merchant] ||= report_group_for_currency(currency)

      # Go to Litle
      gateway = Killbill::Litle.gateway_for_currency(currency)
      litle_response = gateway.credit amount_in_cents, litle_transaction.litle_txn_id, options
      response = save_response_and_transaction litle_response, :refund, kb_payment_id, amount_in_cents

      response.to_refund_response
    end

    def get_refund_info(kb_account_id, kb_payment_id, tenant_context = nil, options = {})
      # We assume the refund is immutable in Litle and only look at our tables since there
      # doesn't seem to be a Litle API to fetch details for a given transaction.
      litle_transaction = LitleTransaction.refund_from_kb_payment_id(kb_payment_id)

      litle_transaction.litle_response.to_refund_response
    end

    def add_payment_method(kb_account_id, kb_payment_method_id, payment_method_props, set_default, call_context = nil, options = {})
      # Set a default report group
      options[:merchant] ||= report_group_for_account(kb_account_id)

      # TODO Add support for real credit cards
      token = find_value_from_payment_method_props payment_method_props, 'paypageRegistrationId'

      currency = account_currency(kb_account_id)
      gateway = Killbill::Litle.gateway_for_currency(currency)
      litle_response = gateway.store token, options
      response = save_response_and_transaction litle_response, :add_payment_method

      if response.success
        LitlePaymentMethod.create :kb_account_id => kb_account_id,
                                  :kb_payment_method_id => kb_payment_method_id,
                                  :litle_token => response.litle_token,
                                  :cc_first_name => find_value_from_payment_method_props(payment_method_props, 'ccFirstName'),
                                  :cc_last_name => find_value_from_payment_method_props(payment_method_props, 'ccLastName'),
                                  :cc_type => find_value_from_payment_method_props(payment_method_props, 'ccType'),
                                  :cc_exp_month => find_value_from_payment_method_props(payment_method_props, 'ccExpMonth'),
                                  :cc_exp_year => find_value_from_payment_method_props(payment_method_props, 'ccExpYear'),
                                  :cc_last_4 => find_value_from_payment_method_props(payment_method_props, 'ccLast4'),
                                  :address1 => find_value_from_payment_method_props(payment_method_props, 'address1'),
                                  :address2 => find_value_from_payment_method_props(payment_method_props, 'address2'),
                                  :city => find_value_from_payment_method_props(payment_method_props, 'city'),
                                  :state => find_value_from_payment_method_props(payment_method_props, 'state'),
                                  :zip => find_value_from_payment_method_props(payment_method_props, 'zip'),
                                  :country => find_value_from_payment_method_props(payment_method_props, 'country')
      else
        raise response.message
      end
    end

    def delete_payment_method(kb_account_id, kb_payment_method_id, call_context = nil, options = {})
      LitlePaymentMethod.mark_as_deleted! kb_payment_method_id
    end

    def get_payment_method_detail(kb_account_id, kb_payment_method_id, tenant_context = nil, options = {})
      LitlePaymentMethod.from_kb_payment_method_id(kb_payment_method_id).to_payment_method_response
    end

    def set_default_payment_method(kb_account_id, kb_payment_method_id, call_context = nil, options = {})
      # No-op
    end

    def get_payment_methods(kb_account_id, refresh_from_gateway = false, call_context = nil, options = {})
      LitlePaymentMethod.from_kb_account_id(kb_account_id).collect { |pm| pm.to_payment_method_info_response }
    end

    def reset_payment_methods(kb_account_id, payment_methods)
      return if payment_methods.nil?

      litle_pms = LitlePaymentMethod.from_kb_account_id(kb_account_id)

      payment_methods.delete_if do |payment_method_info_plugin|
        should_be_deleted = false
        litle_pms.each do |litle_pm|
          # Do litle_pm and payment_method_info_plugin represent the same Litle payment method?
          if litle_pm.external_payment_method_id == payment_method_info_plugin.external_payment_method_id
            # Do we already have a kb_payment_method_id?
            if litle_pm.kb_payment_method_id == payment_method_info_plugin.payment_method_id
              should_be_deleted = true
              break
            elsif litle_pm.kb_payment_method_id.nil?
              # We didn't have the kb_payment_method_id - update it
              litle_pm.kb_payment_method_id = payment_method_info_plugin.payment_method_id
              should_be_deleted = litle_pm.save
              break
              # Otherwise the same token points to 2 different kb_payment_method_id. This should never happen,
              # but we cowardly will insert a second row below
            end
          end
        end

        should_be_deleted
      end

      # The remaining elements in payment_methods are not in our table (this should never happen?!)
      payment_methods.each do |payment_method_info_plugin|
        LitlePaymentMethod.create :kb_account_id => payment_method_info_plugin.account_id,
                                  :kb_payment_method_id => payment_method_info_plugin.payment_method_id,
                                  :litle_token => payment_method_info_plugin.external_payment_method_id
      end
    end

    private

    def find_value_from_payment_method_props(payment_method_props, key)
      prop = (payment_method_props.properties.find { |kv| kv.key == key })
      prop.nil? ? nil : prop.value
    end

    def report_group_for_account(kb_account_id)
      currency = account_currency(kb_account_id)
      report_group_for_currency(currency)
    rescue => e
      'Default Report Group'
    end

    def account_currency(kb_account_id)
      account = @kb_apis.account_user_api.get_account_by_id(kb_account_id, @kb_apis.create_context)
      account.currency
    end

    def report_group_for_currency(currency)
      "Report Group for #{currency.to_s}"
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
        transaction = response.create_litle_transaction!(:amount_in_cents => amount_in_cents,
                                                         :api_call => api_call,
                                                         :kb_payment_id => kb_payment_id,
                                                         :litle_txn_id => response.litle_txn_id)
        @logger.debug "Recorded transaction: #{transaction.inspect}"
      end
      response
    end
  end
end
