require 'active_record'

class LitleResponse < ActiveRecord::Base
  attr_accessible :kb_payment_id,
                  :message,
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

  def self.from_response(kb_payment_id, response)
    LitleResponse.new({
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

  private

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
