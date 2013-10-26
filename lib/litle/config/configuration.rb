require 'logger'

module Killbill::Litle
  mattr_reader :logger
  mattr_reader :config
  mattr_reader :gateways
  mattr_reader :kb_apis
  mattr_reader :initialized
  mattr_reader :test

  def self.initialize!(logger=Logger.new(STDOUT), conf_dir=File.expand_path('../../../', File.dirname(__FILE__)), kb_apis = nil)
    @@logger = logger
    @@kb_apis = kb_apis

    config_file = "#{conf_dir}/litle.yml"
    @@config = Properties.new(config_file)
    @@config.parse!
    @@test = @@config[:litle][:test]

    @@logger.log_level = Logger::DEBUG if (@@config[:logger] || {})[:debug]

    @@gateways = Killbill::Litle::Gateway.from_config(@@config[:litle])

    if defined?(JRUBY_VERSION)
      # See https://github.com/jruby/activerecord-jdbc-adapter/issues/302
      require 'jdbc/mysql'
      Jdbc::MySQL.load_driver(:require) if Jdbc::MySQL.respond_to?(:load_driver)
    end

    ActiveRecord::Base.establish_connection(@@config[:database])
    ActiveRecord::Base.logger = @@logger

    @@initialized = true
  end

  def self.gateway_for_currency(currency)
    currency_sym = currency.to_s.upcase.to_sym
    gateway = @@gateways[currency_sym]
    raise "Gateway for #{currency} not configured!" if gateway.nil?
    gateway
  end
end
