require 'bundler'
require 'litle'
require 'killbill/helpers/active_merchant/killbill_spec_helper'

require 'logger'

require 'rspec'

RSpec.configure do |config|
  config.color_enabled = true
  config.tty = true
  config.formatter = 'documentation'
  config.before(:each) do
    Dir.mktmpdir do |dir|
      file = File.new(File.join(dir, 'litle.yml'), 'w+')
      file.write(<<-eos)
:litle:
  :account_id: "USD"
  :merchant_id: "#{ENV['LITLE_MERCHANT_ID']}"
  :login: "#{ENV['LITLE_LOGIN']}"
  :password: "#{ENV['LITLE_PASSWORD']}"
  :test_url: "#{ENV['LITLE_TEST_URL']}"
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
end

require 'active_record'
ActiveRecord::Base.establish_connection(
    :adapter => 'sqlite3',
    :database => 'test.db'
)
# For debugging
#ActiveRecord::Base.logger = Logger.new(STDOUT)
# Create the schema
require File.expand_path(File.dirname(__FILE__) + '../../db/schema.rb')

