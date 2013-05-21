

module Killbill::Litle
  class LitleResponse < ActiveRecord::Base
    has_one :litle_transaction
    attr_accessible :api_call,
                    :kb_payment_id,
                    :message,
                    # Either litleToken (registerToken call) or litleTxnId
                    :authorization,
                    :fraud_review,
                    :test,
                    :params_litleonelineresponse_message,
                    :params_litleonelineresponse_response,
                    :params_litleonelineresponse_version,
                    :params_litleonelineresponse_xmlns,
                    :params_litleonelineresponse_saleresponse_customer_id,
                    :params_litleonelineresponse_saleresponse_id,
                    :params_litleonelineresponse_saleresponse_report_group,
                    :params_litleonelineresponse_saleresponse_litle_txn_id,
                    :params_litleonelineresponse_saleresponse_order_id,
                    :params_litleonelineresponse_saleresponse_response,
                    :params_litleonelineresponse_saleresponse_response_time,
                    :params_litleonelineresponse_saleresponse_message,
                    :params_litleonelineresponse_saleresponse_auth_code,
                    :avs_result_code,
                    :avs_result_message,
                    :avs_result_street_match,
                    :avs_result_postal_match,
                    :cvv_result_code,
                    :cvv_result_message,
                    :success

    def litle_token
      authorization
    end

    def litle_txn_id
      potential_litle_txn_id = params_litleonelineresponse_saleresponse_litle_txn_id || authorization
      if potential_litle_txn_id.blank?
        nil
      else
        # Litle seems to return the precision sometimes along with the txnId (e.g. 053499651324799+19)
        # And sometimes it adds a ;credit
        # TODO Figure out WTF is going on here
        ("%f" % potential_litle_txn_id.split(';')[0].split('+')[0]).to_i
      end
    end

    def self.from_response(api_call, kb_payment_id, response)
      LitleResponse.new({
                          :api_call => api_call,
                          :kb_payment_id => kb_payment_id,
                          :message => response.message,
                          :authorization => response.authorization,
                          :fraud_review => response.fraud_review?,
                          :test => response.test?,
                          :params_litleonelineresponse_message => extract(response, "litleOnlineResponse", "message"),
                          :params_litleonelineresponse_response => extract(response, "litleOnlineResponse", "response"),
                          :params_litleonelineresponse_version => extract(response, "litleOnlineResponse", "version"),
                          :params_litleonelineresponse_xmlns => extract(response, "litleOnlineResponse", "xmlns"),
                          :params_litleonelineresponse_saleresponse_customer_id => extract(response, "litleOnlineResponse", "saleResponse", "customerId"),
                          :params_litleonelineresponse_saleresponse_id => extract(response, "litleOnlineResponse", "saleResponse", "id"),
                          :params_litleonelineresponse_saleresponse_report_group => extract(response, "litleOnlineResponse", "saleResponse", "reportGroup"),
                          :params_litleonelineresponse_saleresponse_litle_txn_id => extract(response, "litleOnlineResponse", "saleResponse", "litleTxnId"),
                          :params_litleonelineresponse_saleresponse_order_id => extract(response, "litleOnlineResponse", "saleResponse", "orderId"),
                          :params_litleonelineresponse_saleresponse_response => extract(response, "litleOnlineResponse", "saleResponse", "response"),
                          :params_litleonelineresponse_saleresponse_response_time => extract(response, "litleOnlineResponse", "saleResponse", "responseTime"),
                          :params_litleonelineresponse_saleresponse_message => extract(response, "litleOnlineResponse", "saleResponse", "message"),
                          :params_litleonelineresponse_saleresponse_auth_code => extract(response, "litleOnlineResponse", "saleResponse", "authCode"),
                          :avs_result_code => response.avs_result.kind_of?(ActiveMerchant::Billing::AVSResult) ? response.avs_result.code : response.avs_result['code'],
                          :avs_result_message => response.avs_result.kind_of?(ActiveMerchant::Billing::AVSResult) ? response.avs_result.message : response.avs_result['message'],
                          :avs_result_street_match => response.avs_result.kind_of?(ActiveMerchant::Billing::AVSResult) ? response.avs_result.street_match : response.avs_result['street_match'],
                          :avs_result_postal_match => response.avs_result.kind_of?(ActiveMerchant::Billing::AVSResult) ? response.avs_result.postal_match : response.avs_result['postal_match'],
                          :cvv_result_code => response.cvv_result.kind_of?(ActiveMerchant::Billing::CVVResult) ? response.cvv_result.code : response.cvv_result['code'],
                          :cvv_result_message => response.cvv_result.kind_of?(ActiveMerchant::Billing::CVVResult) ? response.cvv_result.message : response.cvv_result['message'],
                          :success => response.success?
                       })
    end

    def to_payment_response
      to_killbill_response :payment
    end

    def to_refund_response
      to_killbill_response :refund
    end

    private

    def to_killbill_response(type)
      if litle_transaction.nil?
        amount_in_cents = nil
        created_date = created_at
        first_payment_reference_id = nil
        second_payment_reference_id = nil
      else
        amount_in_cents = litle_transaction.amount_in_cents
        created_date = litle_transaction.created_at
        first_payment_reference_id = litle_transaction.litle_txn_id
        second_payment_reference_id = litle_transaction.id.to_s
      end

      effective_date = params_litleonelineresponse_saleresponse_response_time || created_date
      gateway_error = message || params_litleonelineresponse_saleresponse_message
      gateway_error_code = params_litleonelineresponse_saleresponse_response

      if type == :payment
        status = success ? Killbill::Plugin::Model::PaymentPluginStatus.new(:PROCESSED) : Killbill::Plugin::Model::PaymentPluginStatus.new(:ERROR)
        Killbill::Plugin::Model::PaymentInfoPlugin.new(amount_in_cents, created_date, effective_date, status, gateway_error, gateway_error_code, first_payment_reference_id, second_payment_reference_id)
      else
        status = success ? Killbill::Plugin::Model::RefundPluginStatus.new(:PROCESSED) : Killbill::Plugin::Model::RefundPluginStatus.new(:ERROR)
        Killbill::Plugin::Model::RefundInfoPlugin.new(amount_in_cents, created_date, effective_date, status, gateway_error, gateway_error_code, first_payment_reference_id)
      end
    end

    def self.extract(response, key1, key2=nil, key3=nil)
      return nil if response.nil? || response.params.nil?
      level1 = response.params[key1]

      if level1.nil? or (key2.nil? and key3.nil?)
        return level1
      end
      level2 = level1[key2]

      if level2.nil? or key3.nil?
        return level2
      else
        return level2[key3]
      end
    end
  end
end
