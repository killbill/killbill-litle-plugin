require 'spec_helper'
require 'pp'

describe Killbill::Litle::PaymentPlugin do

  include ::Killbill::Plugin::ActiveMerchant::RSpec

  it 'should start and stop correctly' do
    @plugin.stop_plugin
  end

  it 'should select the default payment processor account' do 
    ::Killbill::Litle::LitlePaymentMethod.delete_all
    ::Killbill::Litle::LitleResponse.delete_all
    ::Killbill::Litle::LitleTransaction.delete_all

    @call_context = build_call_context

    @properties = []
    @pm         = create_payment_method(::Killbill::Litle::LitlePaymentMethod, nil, @call_context.tenant_id, @properties)
    @amount     = BigDecimal.new('100')
    @currency   = "CAD"

    kb_payment_id = SecureRandom.uuid
    1.upto(6) do
      @kb_payment = @plugin.kb_apis.proxied_services[:payment_api].add_payment(kb_payment_id)
    end

    properties = build_pm_properties

    payment_response = @plugin.purchase_payment(@pm.kb_account_id, @kb_payment.id, @kb_payment.transactions[0].id, @pm.kb_payment_method_id, @amount, @currency, properties, @call_context)
    pp payment_response.properties
    expect((payment_response.properties.find { |kv| kv.key.to_s == 'payment_processor_account_id' }).value.to_s).to eq('USD')
  end

  it 'should select the correct payment processor' do
    ::Killbill::Litle::LitlePaymentMethod.delete_all
    ::Killbill::Litle::LitleResponse.delete_all
    ::Killbill::Litle::LitleTransaction.delete_all

    @call_context = build_call_context

    @properties = []
    @pm         = create_payment_method(::Killbill::Litle::LitlePaymentMethod, nil, @call_context.tenant_id, @properties)
    @amount     = BigDecimal.new('100')
    @currency   = "EUR"

    kb_payment_id = SecureRandom.uuid
    1.upto(6) do
      @kb_payment = @plugin.kb_apis.proxied_services[:payment_api].add_payment(kb_payment_id)
    end

    properties = build_pm_properties

    payment_response = @plugin.purchase_payment(@pm.kb_account_id, @kb_payment.id, @kb_payment.transactions[0].id, @pm.kb_payment_method_id, @amount, @currency, properties, @call_context)
    pp payment_response.properties
    expect((payment_response.properties.find { |kv| kv.key.to_s == 'payment_processor_account_id' }).value.to_s).to eq(@currency)
  end
  # No offsite payments integration

  #xit 'should generate forms correctly' do
  #  kb_account_id = SecureRandom.uuid
  #  kb_tenant_id  = SecureRandom.uuid
  #  context       = @plugin.kb_apis.create_context(kb_tenant_id)
  #  fields        = @plugin.hash_to_properties({
  #                                                 :order_id => '1234',
  #                                                 :amount   => 10
  #                                             })
  #  form          = @plugin.build_form_descriptor kb_account_id, fields, [], context
  #
  #  form.kb_account_id.should == kb_account_id
  #  form.form_method.should == 'POST'
  #  form.form_url.should == 'https://litle.com'
  #
  #  form_fields = @plugin.properties_to_hash(form.form_fields)
  #end

  #xit 'should receive notifications correctly' do
  #  description    = 'description'
  #
  #  kb_tenant_id = SecureRandom.uuid
  #  context      = @plugin.kb_apis.create_context(kb_tenant_id)
  #  properties   = @plugin.hash_to_properties({ :description => description })
  #
  #  notification    = ""
  #  gw_notification = @plugin.process_notification notification, properties, context
  #end
end
