module Killbill::Litle
  class Gateway
    def self.from_config(config)
      if config[:test]
        ActiveMerchant::Billing::Base.mode = :test
      end

      if config[:log_file]
        ActiveMerchant::Billing::LitleGateway.wiredump_device = File.open(config[:log_file], 'w')
        ActiveMerchant::Billing::LitleGateway.wiredump_device.sync = true
      end

      gateways = {}
      config[:merchant_id].each do |currency, mid|
        gateways[currency.upcase.to_sym] = Gateway.new(currency, config[:username], config[:password], mid)
      end
      gateways
    end

    def initialize(currency, user, password, merchant_id)
      @currency = currency
      @gateway = ActiveMerchant::Billing::LitleGateway.new({:user => user,
                                                            :password => password,
                                                            :merchant_id => merchant_id
                                                           })
    end

    def method_missing(m, *args, &block)
      @gateway.send(m, *args, &block)
    end
  end
end
