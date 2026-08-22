require 'abcbank/version'
require 'active_support/all'
require 'abcbank/config'
require 'abcbank/helper'
require 'abcbank/crypt'
require 'abcbank/request'

lib_path = "#{File.dirname(__FILE__)}/abcbank"
Dir["#{lib_path}/apis/**/*.rb"].each { |path| require path }

require 'abcbank/api'

module Abcbank
  class Error < StandardError; end
  class AppNotConfigException < Error; end
  class ConfigError < Error; end
  class SignatureVerificationError < Error; end
  class DecryptError < Error; end

  class HttpError < Error
    attr_reader :status, :body

    def initialize(status, body = '')
      @status = status
      @body = body
      super "(#{status}) #{body}"
    end
  end

  class RateLimitedError < HttpError; end

  class ResultError < Error
    attr_reader :code, :msg

    def initialize(code, msg = '')
      @code = code
      @msg = msg
      super "(#{code}) #{msg}"
    end
  end
end
