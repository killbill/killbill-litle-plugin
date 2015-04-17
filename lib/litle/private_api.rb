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

      def add_payment_method(params)
        payment_processor_account_id = params[:payment_processor_account_id] || :default

        exp_month, exp_year = (params[:exp_date] || '').split('/')

        # TODO Save response row (to keep the response_litle_txn_id)

        # Create the payment method (not associated with a Kill Bill payment method yet)
        Killbill::Litle::LitlePaymentMethod.create!(:kb_account_id        => params[:kb_account_id],
                                                    :kb_payment_method_id => nil,
                                                    :kb_tenant_id         => params[:kb_tenant_id],
                                                    :token                => params[:response_paypage_registration_id],
                                                    :cc_first_name        => params[:first_name],
                                                    :cc_last_name         => params[:last_name],
                                                    :cc_type              => nil,
                                                    :cc_exp_month         => exp_month,
                                                    :cc_exp_year          => exp_year,
                                                    :cc_last_4            => params[:cc_num],
                                                    :address1             => nil,
                                                    :address2             => nil,
                                                    :city                 => nil,
                                                    :state                => nil,
                                                    :zip                  => nil,
                                                    :country              => nil,
                                                    :created_at           => Time.now.utc,
                                                    :updated_at           => Time.now.utc)
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
