module Killbill::Litle
  class LitlePaymentMethod < ActiveRecord::Base
    attr_accessible :kb_account_id, :kb_payment_method_id, :litle_token

    def self.from_kb_account_id(kb_account_id)
      find_all_by_kb_account_id_and_is_deleted(kb_account_id, false)
    end

    def self.from_kb_payment_method_id(kb_payment_method_id)
      payment_methods = find_all_by_kb_payment_method_id_and_is_deleted(kb_payment_method_id, false)
      raise "No payment method found for payment method #{kb_payment_method_id}" if payment_methods.empty?
      raise "Killbill payment method mapping to multiple active Litle tokens for payment method #{kb_payment_method_id}" if payment_methods.size > 1
      payment_methods[0]
    end

    def self.mark_as_deleted!(kb_payment_method_id)
      payment_method = from_kb_payment_method_id(kb_payment_method_id)
      payment_method.is_deleted = true
      payment_method.save!
    end

    def to_payment_method_response
      external_payment_method_id = litle_token
      # No concept of default payment method in Litle
      is_default = false
      # No extra information is stored in Litle
      properties = []

      Killbill::Plugin::Model::PaymentMethodPlugin.new(external_payment_method_id, is_default, properties, "CreditCard", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil)
    end
  end
end
