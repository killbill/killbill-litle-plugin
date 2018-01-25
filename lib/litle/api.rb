module Killbill #:nodoc:
  module Litle #:nodoc:
    class PaymentPlugin < ::Killbill::Plugin::ActiveMerchant::PaymentPlugin

      def initialize
        gateway_builder = Proc.new do |config|
          ::ActiveMerchant::Billing::LitleGateway.new :login => config[:login],
                                                      :password => config[:password],
                                                      :merchant_id => config[:merchant_id]
        end

        super(gateway_builder,
              :litle,
              ::Killbill::Litle::LitlePaymentMethod,
              ::Killbill::Litle::LitleTransaction,
              ::Killbill::Litle::LitleResponse)
      end

      def on_event(event)
        # Require to deal with per tenant configuration invalidation
        super(event)
        #
        # Custom event logic could be added below...
        #
      end

      # TODO Should we set the Litle Id field to check for dups (https://www.litle.com/mc-secure/DupeChecking_V1.2.pdf)?

      def authorize_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context)
        # Pass extra parameters for the gateway here
        options = {}

        paypage_registration_id = find_value_from_properties(properties, 'paypageRegistrationId')
        options[:paypage_registration_id] = paypage_registration_id unless paypage_registration_id.blank?

        properties = merge_properties(properties, options)
        super(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context)
      end

      def capture_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context)
        # Pass extra parameters for the gateway here
        options = {}

        properties = merge_properties(properties, options)
        super(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context)
      end

      def purchase_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context)
        # Pass extra parameters for the gateway here
        options = {}

        properties = merge_properties(properties, options)
        super(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context)
      end

      def void_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, properties, context)
        # Pass extra parameters for the gateway here
        options = {}

        properties = merge_properties(properties, options)
        super(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, properties, context)
      end

      def credit_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context)
        # Pass extra parameters for the gateway here
        options = {}

        properties = merge_properties(properties, options)
        super(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context)
      end

      def refund_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context)
        gateway_call_proc = Proc.new do |gateway, linked_transaction, payment_source, amount_in_cents, options|
          gateway.refund(amount_in_cents, linked_transaction.txn_id, options)
        end

        linked_transaction_proc = Proc.new do |amount_in_cents, options|
          # we need the id of either a capture or sale transaction
          transaction = @transaction_model.find_candidate_transaction_for_refund(kb_payment_id, context.tenant_id, :CAPTURE)
          if transaction.nil?
            transaction = @transaction_model.find_candidate_transaction_for_refund(kb_payment_id, context.tenant_id, :PURCHASE)
          end
          # This should never happen
          raise "Unable to retrieve transaction to refund for operation=refund, kb_payment_id=#{kb_payment_id}, kb_payment_transaction_id=#{kb_payment_transaction_id}, kb_payment_method_id=#{kb_payment_method_id}" if transaction.nil?
          transaction
        end

        dispatch_to_gateways(:refund, kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context, gateway_call_proc, linked_transaction_proc)
      end

      def get_payment_info(kb_account_id, kb_payment_id, properties, context)
        # Pass extra parameters for the gateway here
        options = {}

        properties = merge_properties(properties, options)
        super(kb_account_id, kb_payment_id, properties, context)
      end

      def search_payments(search_key, offset, limit, properties, context)
        # Pass extra parameters for the gateway here
        options = {}

        properties = merge_properties(properties, options)
        super(search_key, offset, limit, properties, context)
      end

      def add_payment_method(kb_account_id, kb_payment_method_id, payment_method_props, set_default, properties, context)
        # paypageRegistrationId is passed via properties
        paypage_registration_id = find_value_from_properties(properties, 'paypageRegistrationId')
        # paypageRegistrationId is passed from the json body
        paypage_registration_id = find_value_from_properties(payment_method_props.properties, 'paypageRegistrationId') if paypage_registration_id.nil?

        # Pass extra parameters for the gateway here
        options = {}

        # Register the token
        unless paypage_registration_id.nil?
          payment_processor_account_id = options[:payment_processor_account_id] || :default
          gateway                      = lookup_gateway(payment_processor_account_id, context.tenant_id)
          litle_response               = gateway.register_token_request(paypage_registration_id, options)
          response, _                  = save_response_and_transaction(litle_response, :register_token_request, kb_account_id, context.tenant_id, payment_processor_account_id)
          raise response.message unless response.success

          options[:skip_gw] = true
          options[:token] = litle_response.authorization
        end

        properties = merge_properties(properties, options)
        super(kb_account_id, kb_payment_method_id, payment_method_props, set_default, properties, context)
      end

      def delete_payment_method(kb_account_id, kb_payment_method_id, properties, context)
        # Pass extra parameters for the gateway here
        options = {}

        properties = merge_properties(properties, options)
        super(kb_account_id, kb_payment_method_id, properties, context)
      end

      def get_payment_method_detail(kb_account_id, kb_payment_method_id, properties, context)
        # Pass extra parameters for the gateway here
        options = {}

        properties = merge_properties(properties, options)
        super(kb_account_id, kb_payment_method_id, properties, context)
      end

      def set_default_payment_method(kb_account_id, kb_payment_method_id, properties, context)
        # TODO
      end

      def get_payment_methods(kb_account_id, refresh_from_gateway, properties, context)
        # Pass extra parameters for the gateway here
        options = {}

        properties = merge_properties(properties, options)
        super(kb_account_id, refresh_from_gateway, properties, context)
      end

      def search_payment_methods(search_key, offset, limit, properties, context)
        # Pass extra parameters for the gateway here
        options = {}

        properties = merge_properties(properties, options)
        super(search_key, offset, limit, properties, context)
      end

      def reset_payment_methods(kb_account_id, payment_methods, properties, context)
        super
      end

      def build_form_descriptor(kb_account_id, descriptor_fields, properties, context)
        # Pass extra parameters for the gateway here
        options = {}
        properties = merge_properties(properties, options)

        # Add your custom static hidden tags here
        options = {
            #:token => config[:litle][:token]
        }
        descriptor_fields = merge_properties(descriptor_fields, options)

        super(kb_account_id, descriptor_fields, properties, context)
      end

      def process_notification(notification, properties, context)
        # Pass extra parameters for the gateway here
        options = {}
        properties = merge_properties(properties, options)

        super(notification, properties, context) do |gw_notification, service|
          # Retrieve the payment
          # gw_notification.kb_payment_id =
          #
          # Set the response body
          # gw_notification.entity =
        end
      end
    end
  end
end
