module Killbill #:nodoc:
  module Litle #:nodoc:
    class LitlePaymentMethod < ::Killbill::Plugin::ActiveMerchant::ActiveRecord::PaymentMethod

      self.table_name = 'litle_payment_methods'

      def self.from_response(kb_account_id, kb_payment_method_id, kb_tenant_id, cc_or_token, response, options, extra_params = {}, model = ::Killbill::Litle::LitlePaymentMethod)
        super(kb_account_id,
              kb_payment_method_id,
              kb_tenant_id,
              cc_or_token,
              response,
              options,
              {
                  :token => extract(response, 'litleToken')
              }.merge!(extra_params),
              model)
      end
    end
  end
end
