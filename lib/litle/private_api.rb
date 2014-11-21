module Killbill #:nodoc:
  module Litle #:nodoc:
    class PrivatePaymentPlugin < ::Killbill::Plugin::ActiveMerchant::PrivatePaymentPlugin
      def initialize(session = {})
        super(:litle,
              ::Killbill::Litle::LitlePaymentMethod,
              ::Killbill::Litle::LitleTransaction,
              ::Killbill::Litle::LitleResponse,
              session)
      end

      def get_currency(kb_account_id)
        account = kb_apis.get_account_by_id(kb_account_id)
        account.currency
      rescue => e
        'USD'
      end
    end
  end
end
