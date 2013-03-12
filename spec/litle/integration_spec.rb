require 'spec_helper'
require 'logger'

ActiveMerchant::Billing::Base.mode = :test

describe Killbill::Litle::PaymentPlugin do
  before(:each) do
    @plugin = Killbill::Litle::PaymentPlugin.new
    @plugin.root = File.expand_path(File.dirname(__FILE__) + '../../../')
    @plugin.logger = Logger.new(STDOUT)
    @plugin.start_plugin
  end

  after(:each) do
    @plugin.stop_plugin
  end

  it "should connect to the sandbox" do
    pm = create_payment_method
    amount_in_cents = 10000
    kb_payment_id = '11223344'

    @plugin.charge kb_payment_id, pm.kb_payment_method_id, amount_in_cents

    response = LitleResponse.find_by_kb_payment_id kb_payment_id
    response.test.should be_true
    response.success.should be_true
    response.message.should == "Approved"
    response.params_litleonelineresponse_saleresponse_order_id.should == kb_payment_id
  end

  private

  def create_payment_method
    kb_payment_method_id = '5678'
    # litle tokens are between 13 and 25 characters long
    litle_token = 17283748291029384756
    LitlePaymentMethod.create :kb_payment_method_id => kb_payment_method_id, :litle_token => litle_token
  end
end
