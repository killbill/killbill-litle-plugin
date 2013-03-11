require 'spec_helper'
require 'logger'
require 'tempfile'

describe Killbill::Litle::PaymentPlugin do
  before(:each) do
    file = Tempfile.new('litle')
    file.write(<<-eos)
:litle:
  :merchant_id: 'merchant_id'
  :password: 'password'
eos
    file.flush

    @plugin = Killbill::Litle::PaymentPlugin.new
    @plugin.root = File.dirname(file)
    @plugin.config_file_name = File.basename(file)
    @plugin.logger = Logger.new(STDOUT)
  end

  it "should start and stop correctly" do
    @plugin.start_plugin
    @plugin.stop_plugin
  end
end
