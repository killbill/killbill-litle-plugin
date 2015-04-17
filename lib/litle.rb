require 'openssl'
require 'action_controller'
require 'active_record'
require 'action_view'
require 'active_merchant'
require 'active_support'
require 'bigdecimal'
require 'money'
require 'monetize'
require 'offsite_payments'
require 'pathname'
require 'sinatra'
require 'singleton'
require 'yaml'

require 'killbill'
require 'killbill/helpers/active_merchant'

require 'litle/api'
require 'litle/private_api'

require 'litle/models/payment_method'
require 'litle/models/response'
require 'litle/models/transaction'

# TODO submit patch
module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class LitleGateway < Gateway
      def register_token_request(paypage_registration_id, options = {})
        request = build_xml_request do |doc|
          add_authentication(doc)
          doc.registerTokenRequest(transaction_attributes(options)) do
            doc.orderId((options[:order_id] || '')[0..24])
            doc.paypageRegistrationId(paypage_registration_id)
          end
        end

        commit(:registerToken, request)
      end
    end
  end
end