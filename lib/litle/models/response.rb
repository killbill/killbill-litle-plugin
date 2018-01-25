module Killbill #:nodoc:
  module Litle #:nodoc:
    class LitleResponse < ::Killbill::Plugin::ActiveMerchant::ActiveRecord::Response

      self.table_name = 'litle_responses'

      has_one :litle_transaction

      def self.from_response(api_call, kb_account_id, kb_payment_id, kb_payment_transaction_id, transaction_type, payment_processor_account_id, kb_tenant_id, response, extra_params = {}, model = ::Killbill::Litle::LitleResponse)
        super(api_call,
              kb_account_id,
              kb_payment_id,
              kb_payment_transaction_id,
              transaction_type,
              payment_processor_account_id,
              kb_tenant_id,
              response,
              {
                  :params_litle_txn_id  => extract(response, 'litleTxnId'),
                  :params_order_id      => extract(response, 'orderId') || extract(response, 'id'),
                  :params_litle_token   => extract(response, 'litleToken'),
                  :params_auth_code     => extract(response, 'authCode'),
                  :params_response      => extract(response, 'response'),
                  :params_response_time => extract(response, 'responseTime'),
                  :params_message       => extract(response, 'message'),
                  :approved_amount      => extract(response, 'approvedAmount'),
              }.merge!(extra_params),
              model)
      end

      def self.search_where_clause(t, search_key)
        where_clause = t[:params_litle_txn_id].eq(search_key)

        # Only search successful payments and refunds
        where_clause = where_clause.and(t[:success].eq(true))

        super.or(where_clause)
      end

      def first_reference_id
        params_litle_txn_id
      end

      def to_transaction_info_plugin(transaction=nil)
        t_info_plugin = super(transaction)
        t_info_plugin.properties << create_plugin_property('approvedAmount', approved_amount)
        t_info_plugin
      end
    end
  end
end
