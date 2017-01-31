require 'spec_helper'

describe Killbill::Litle::PaymentPlugin do

  include ::Killbill::Plugin::ActiveMerchant::RSpec

  before(:each) do
    Dir.mktmpdir do |dir|
      file = File.new(File.join(dir, 'litle.yml'), 'w+')
      file.write(<<-eos)
:litle:
  :account_id: "USD"
  :merchant_id: "#{ENV['LITLE_MERCHANT_ID']}"
  :username: "#{ENV['LITLE_USERNAME']}"
  :password: "#{ENV['LITLE_PASSWORD']}"
  :secure_page_url: "#{ENV['LITLE_SECURE_PAGE_URL']}"
  :paypage_id: "litle-paypage-id-USD"
  :test: true
# As defined by spec_helper.rb
:database:
  :adapter: 'sqlite3'
  :database: 'test.db'
      eos
      file.close

      @plugin = build_plugin(::Killbill::Litle::PaymentPlugin, 'litle', File.dirname(file))

      # Start the plugin here - since the config file will be deleted
      @plugin.start_plugin
    end
  end

  it 'should start and stop correctly' do
    @plugin.stop_plugin
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
