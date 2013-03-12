require 'killbill'
require 'litle/config'
require 'litle/gateway'
require 'litle/litle_payment_method'
require 'litle/litle_response'

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

      payment_method = LitlePaymentMethod.find_by_kb_payment_method_id(kb_payment_method_id)
      raise "No payment method found for payment method #{kb_payment_method_id}" if payment_method.nil?

      token = payment_method.litle_token
      response = @gateway.purchase amount_in_cents, token, options
      LitleResponse.from_response(kb_payment_id, response).save
    end

    def refund(killbill_account_id, killbill_payment_id, amount_in_cents, options = {})
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
  end
end
