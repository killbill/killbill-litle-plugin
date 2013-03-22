require 'spec_helper'

describe Killbill::Litle::PaymentPlugin do
  before(:each) do
    Dir.mktmpdir do |dir|
      file = File.new(File.join(dir, 'litle.yml'), "w+")
      file.write(<<-eos)
:litle:
  :merchant_id: 'merchant_id'
  :password: 'password'
:database:
  :adapter: 'sqlite3'
  :database: 'shouldntmatter.db'
eos
      file.close

      @plugin = Killbill::Litle::PaymentPlugin.new
      @plugin.root = File.dirname(file)
      @plugin.logger = Logger.new(STDOUT)

      # Start the plugin here - since the config file will be deleted
      @plugin.start_plugin
    end
  end

  it "should start and stop correctly" do
    @plugin.stop_plugin
  end
end
