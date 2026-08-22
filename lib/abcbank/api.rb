require 'abcbank/request'

module Abcbank
  class Api
    include Helper

    api_mount :enterprise_account
    api_mount :enterprise_payment
    api_mount :digital_currency

    attr_reader :app_id, :app_secret, :pfx_path, :pfx_content, :pfx_password,
                :abc_cert_path, :abc_cert_content, :sign_type, :options

    def initialize(options = {})
      @app_id = options.delete(:app_id) || Abcbank.config.app_id
      @app_secret = options.delete(:app_secret) || Abcbank.config.app_secret
      @pfx_path = options.delete(:pfx_path) || Abcbank.config.pfx_path
      @pfx_content = options.delete(:pfx_content) || Abcbank.config.pfx_content
      @pfx_password = options.delete(:pfx_password) || Abcbank.config.pfx_password
      @abc_cert_path = options.delete(:abc_cert_path) || Abcbank.config.abc_cert_path
      @abc_cert_content = options.delete(:abc_cert_content) || Abcbank.config.abc_cert_content
      @sign_type = options.delete(:sign_type) || Abcbank.config.sign_type || 'SHA256'

      raise AppNotConfigException if @app_id.to_s.empty? || @app_secret.to_s.empty?
      raise AppNotConfigException if @pfx_path.to_s.empty? && @pfx_content.to_s.empty?

      @options = options
    end

    def request
      @request ||= Abcbank::Request.new(self)
    end

    def crypt
      @crypt ||= Abcbank::Crypt.new(self)
    end

    def post(path, payload, headers = {})
      request.post path, payload, headers
    end

    class << self
      def default
        @default ||= new
      end
    end
  end
end
