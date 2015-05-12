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

      def add_auth_purchase_params(doc, money, payment_method, options)
        doc.orderId(truncated_order_id(options))
        doc.amount(money)
        add_order_source(doc, payment_method, options)
        add_billing_address(doc, payment_method, options)
        add_shipping_address(doc, payment_method, options)
        # Pass options to add_payment_method
        add_payment_method(doc, payment_method, options)
        add_pos(doc, payment_method)
        add_descriptor(doc, options)
      end

      # Add support for PayPage registration ids
      alias old_add_payment_method add_payment_method

      def add_payment_method(doc, payment_method, options = {})
        if options.has_key?(:paypageRegistrationId)
          doc.paypage do
            doc.paypageRegistrationId(options[:paypage_registration_id])
            doc.expDate(exp_date(payment_method))
            doc.cardValidationNum(payment_method.verification_value)
          end
        else
          old_add_payment_method(doc, payment_method)
        end
      end

      # Extract attributes
      def parse(kind, xml)
        parsed = {}

        doc = Nokogiri::XML(xml).remove_namespaces!
        response_nodes = doc.xpath("//litleOnlineResponse/#{kind}Response")
        return {} unless !response_nodes.nil? && response_nodes.size == 1
        response_node = response_nodes[0]

        # Extract children elements
        response_node.elements.each do |node|
          if (node.elements.empty?)
            parsed[node.name.to_sym] = node.text
          else
            node.elements.each do |childnode|
              name = "#{node.name}_#{childnode.name}"
              parsed[name.to_sym] = childnode.text
            end
          end
        end

        # Extract attributes
        response_node.keys.each do |key|
          parsed[key.to_sym] ||= response_node[key]
        end

        parsed
      end
    end
  end
end
