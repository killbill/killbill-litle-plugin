module Killbill::Litle
  class Config
    def initialize(file = 'litle.yml')
      @config_file = Pathname.new(file).expand_path
    end

    def parse!
      raise "#{@config_file} is not a valid file" unless @config_file.file?
      @config = YAML.load_file(@config_file.to_s)
      validate!
    end

    def [](key)
      @config[key]
    end

    private

    def validate!
      raise "Bad configuration for Litle plugin. Config is #{@config.inspect}" if @config.blank? || !@config[:litle] || !@config[:litle][:merchant_id] || !@config[:litle][:password]
    end
  end
end
