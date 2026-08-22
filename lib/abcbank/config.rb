require 'logger'

module Abcbank
  TEST_URL = 'https://obgateway.test.abchina.com/AraratGateWay'.freeze
  PROD_URL = 'https://openbank.abchina.com.cn/GateWay'.freeze

  class << self
    def configure
      yield config
    end

    def config
      @config ||= Config.new
    end

    def logger
      @logger ||= if config.logger.nil?
                    defined?(Rails) && Rails.logger ? Rails.logger : Logger.new(STDOUT)
                  else
                    config.logger
                  end
    end

    def http_timeout_options
      config.http_timeout_options || { write: 2, connect: 5, read: 10 }
    end

    def api_base_url
      config.api_base_url || TEST_URL
    end
  end

  class Config
    attr_accessor :app_id, :app_secret,
                  :pfx_path, :pfx_content, :pfx_password,
                  :abc_cert_path, :abc_cert_content,
                  :sign_type, :api_base_url,
                  :http_timeout_options, :logger, :verify_response_sign
  end
end
