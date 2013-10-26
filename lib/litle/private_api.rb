module Killbill::Litle
  class PrivatePaymentPlugin
    include Singleton

    def get_currency(kb_account_id)
      account = kb_apis.get_account_by_id(kb_account_id)
      account.currency
    rescue => e
      'USD'
    end

    private

    def kb_apis
      # The logger should have been configured when the plugin started
      Killbill::Litle.kb_apis
    end
  end
end
