require 'killbill'
require 'litle/config'
require 'litle/gateway'

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

    def charge(killbill_account_id, killbill_payment_id, amount_in_cents, options = {})
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
