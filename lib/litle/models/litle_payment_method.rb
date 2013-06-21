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

    alias_attribute :external_payment_method_id, :litle_token

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
      properties = []
      properties << create_pm_kv_info('token', litle_token)

      pm_plugin = Killbill::Plugin::Model::PaymentMethodPlugin.new
      pm_plugin.external_payment_method_id = external_payment_method_id
      pm_plugin.is_default_payment_method = is_default
      pm_plugin.properties = properties
      pm_plugin.type = 'CreditCard'
      pm_plugin.cc_name = cc_name
      pm_plugin.cc_type = cc_type
      pm_plugin.cc_expiration_month = cc_exp_month
      pm_plugin.cc_expiration_year = cc_exp_year
      pm_plugin.cc_last4 = cc_last_4
      pm_plugin.address1 = address1
      pm_plugin.address2 = address2
      pm_plugin.city = city
      pm_plugin.state = state
      pm_plugin.zip = zip
      pm_plugin.country = country

      pm_plugin
    end

    def to_payment_method_info_response
      pm_info_plugin = Killbill::Plugin::Model::PaymentMethodInfoPlugin.new
      pm_info_plugin.account_id = kb_account_id
      pm_info_plugin.payment_method_id = kb_payment_method_id
      pm_info_plugin.is_default = is_default
      pm_info_plugin.external_payment_method_id = external_payment_method_id
      pm_info_plugin
    end

    def is_default
      # No concept of default payment method in Litle
      false
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

    private

    def create_pm_kv_info(key, value)
      prop = Killbill::Plugin::Model::PaymentMethodKVInfo.new
      prop.key = key
      prop.value = value
      prop
    end
  end
end
