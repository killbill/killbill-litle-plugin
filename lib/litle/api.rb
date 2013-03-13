require 'killbill'
require 'litle/config'
require 'litle/gateway'
require 'litle/litle_payment_method'
require 'litle/litle_response'
require 'litle/litle_transaction'

module Killbill::Litle
  class PaymentPlugin < Killbill::Plugin::Payment
    attr_writer :config_file_name

    def start_plugin
      config = Config.new("#{@root}/#{@config_file_name || 'litle.yml'}")
      config.parse!

      @gateway = Killbill::Litle::Gateway.instance
      @gateway.configure(config[:litle])

      super
      @logger.info "Litle::PaymentPlugin started"
    end

    def charge(kb_payment_id, kb_payment_method_id, amount_in_cents, options = {})
      # Required argument
      options[:order_id] ||= kb_payment_id

      # Retrieve the Litle token
      token = get_token(kb_payment_method_id)

      litle_response = @gateway.purchase amount_in_cents, token, options
      save_response_and_transaction :charge, kb_payment_id, litle_response
    end

    def refund(kb_payment_id, amount_in_cents, options = {})
      litle_transaction = LitleTransaction.find_by_api_call_and_kb_payment_id(:charge, kb_payment_id)
      raise "Unable to find Litle transaction id for payment #{kb_payment_id}" if litle_transaction.nil?

      litle_response = @gateway.credit amount_in_cents, litle_transaction.litle_txn_id
      save_response_and_transaction :refund, kb_payment_id, litle_response
    end

    def get_payment_info(killbill_payment_id, options = {})
    end

    def add_payment_method(payment_method, options = {})
    end

    def delete_payment_method(external_payment_method_id, options = {})
    end

    def update_payment_method(payment_method, options = {})
    end

    def set_default_payment_method(payment_method, options = {})
    end

    def create_account(killbill_account, options = {})
    end

    private

    def get_token(kb_payment_method_id)
      payment_method = LitlePaymentMethod.find_by_kb_payment_method_id(kb_payment_method_id)
      raise "No payment method found for payment method #{kb_payment_method_id}" if payment_method.nil?

      payment_method.litle_token
    end

    def save_response_and_transaction(api_call, kb_payment_id, litle_response)
      @logger.warn "Unsuccessful #{api_call}: #{litle_response.message}" unless litle_response.success?

      # Save the response to our logs
      response = LitleResponse.from_response(api_call, kb_payment_id, litle_response)
      response.save

      if response.success and !response.litle_txn_id.blank?
        # Record the transaction
        transaction = LitleTransaction.create(:api_call => api_call, :kb_payment_id => kb_payment_id, :litle_txn_id => response.litle_txn_id)
        @logger.debug "Recorded transaction: #{transaction.inspect}"
        transaction
      end
    end
  end
end
