module Killbill::Litle
  class LitlePaymentMethod < ActiveRecord::Base
    attr_accessible :kb_account_id,
                    :kb_payment_method_id,
                    :litle_token,
                    :cc_first_name,
                    :cc_last_name,
                    :cc_type,
                    :cc_exp_month,
                    :cc_exp_year,
                    :cc_last_4,
                    :address1,
                    :address2,
                    :city,
                    :state,
                    :zip,
                    :country

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

      properties = []
      properties << Killbill::Plugin::Model::PaymentMethodKVInfo.new(false, "token", litle_token)

      Killbill::Plugin::Model::PaymentMethodPlugin.new(external_payment_method_id,
                                                       is_default,
                                                       properties,
                                                       nil,
                                                       'CreditCard',
                                                       cc_name,
                                                       cc_type,
                                                       cc_exp_month,
                                                       cc_exp_year,
                                                       cc_last_4,
                                                       address1,
                                                       address2,
                                                       city,
                                                       state,
                                                       zip,
                                                       country)
    end

    def to_payment_method_info_response
      external_payment_method_id = litle_token
      # No concept of default payment method in Litle
      is_default = false

      Killbill::Plugin::Model::PaymentMethodInfoPlugin.new(kb_account_id, kb_payment_method_id, is_default, external_payment_method_id)
    end

    def cc_name
      if cc_first_name and cc_last_name
        "#{cc_first_name} #{cc_last_name}"
      elsif cc_first_name
        cc_first_name
      elsif cc_last_name
        cc_last_name
      else
        nil
      end
    end
  end
end
