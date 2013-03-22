module Killbill::Litle
  class Gateway
    include Singleton

    def configure(config)
      if config[:log_file]
        ActiveMerchant::Billing::LitleGateway.wiredump_device = File.open(config[:log_file], 'w')
        ActiveMerchant::Billing::LitleGateway.wiredump_device.sync = true
      end

      @gateway = ActiveMerchant::Billing::LitleGateway.new({
                                                             :merchant_id => config[:merchant_id],
                                                             :password => config[:password]
                                                           })
    end

    def method_missing(m, *args, &block)
      @gateway.send(m, *args, &block)
    end
  end
end
