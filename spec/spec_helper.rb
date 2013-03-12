require 'bundler'
require 'litle'
require 'litle/litle_payment_method'

require 'rspec'

RSpec.configure do |config|
  config.color_enabled = true
  config.tty = true
  config.formatter = 'documentation'
end

require 'active_record'
ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => 'test.db'
)
# Create the schema
require File.expand_path(File.dirname(__FILE__) + '../../db/schema.rb')
