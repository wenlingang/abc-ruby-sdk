require 'http'
require 'json'
require 'securerandom'

module Abcbank
  class Request
    attr_reader :client, :ssl_context, :http

    def initialize(client, skip_verify_ssl = false)
      @client = client
      @http = HTTP.timeout(**Abcbank.http_timeout_options)
      @ssl_context = OpenSSL::SSL::SSLContext.new
      @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE if skip_verify_ssl
    end

    # path 形如 'enterpriseaccount/applyauthorization'
    def post(path, payload, headers = {})
      envelope = build_envelope(payload)
      url = "#{Abcbank.api_base_url}/openabc/api/#{path}/v1"
      header = { 'Content-Type' => 'application/json' }.merge(headers)

      response = http.headers(header).post(url, body: envelope.to_json, ssl_context: ssl_context)
      handle(url, response)
    end

    private

    def build_envelope(payload)
      biz_data = payload.is_a?(String) ? payload : payload.to_json
      envelope = {
        'appid' => client.app_id,
        'sign_type' => client.sign_type,
        'encrypt_type' => 'AES',
        'encrypt_data' => client.crypt.aes_encrypt(biz_data),
        'biz_data' => '',
        'nonce' => SecureRandom.uuid.delete('-'),
        'timestamp' => Time.now.strftime('%Y-%m-%d %H:%M:%S')
      }
      envelope.merge('sign' => client.crypt.sign(Crypt.sign_plaintext(envelope)))
    end

    def handle(url, response)
      raise RateLimitedError.new(response.status.to_i, response.body.to_s) if response.status.to_i == 403

      unless response.status.success?
        Abcbank.logger.error "request #{url} happen error: #{response.body}"
        raise HttpError.new(response.status.to_i, response.body.to_s)
      end

      body = JSON.parse(response.body.to_s)
      verify_sign!(body)
      Result.new(body, decrypt_biz(body))
    end

    def verify_sign!(body)
      return if Abcbank.config.verify_response_sign == false
      return if body['sign'].to_s.empty?

      plaintext = Crypt.sign_plaintext(body)
      return if client.crypt.verify(plaintext, body['sign'])

      raise SignatureVerificationError, "响应报文验签失败, 验签明文: #{plaintext}"
    end

    def decrypt_biz(body)
      if body['biz_encrypt'].to_s.empty?
        body['biz_content']
      else
        client.crypt.aes_decrypt(body['biz_encrypt'])
      end
    end
  end

  class Result
    attr_reader :code, :msg, :responseid, :data, :raw

    def initialize(envelope, biz_plaintext = nil)
      @raw = envelope || {}
      @code = @raw['code'].to_s
      @msg = @raw['msg'].to_s
      @responseid = @raw['responseid'] || @raw['response_id']
      @data = parse_biz(biz_plaintext)
    end

    def success?
      code == '0000'
    end

    def failure?
      !success?
    end

    def data!
      raise ResultError.new(code, msg) unless success?

      data
    end

    private

    def parse_biz(text)
      return {} if text.to_s.empty?

      JSON.parse(text)
    rescue JSON::ParserError
      { '_raw' => text }
    end
  end
end
