require 'activemerchant'
require 'singleton'

module Killbill::Litle
  class Gateway
    include Singleton

    def configure(config)
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
