$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'abcbank'

require 'minitest/autorun'
require 'webmock/minitest'

module AbcbankTestHelper
  TEST_APP_ID = 'test-appid-0000-0000'.freeze
  # 40 字符，与农行 appSecret 规格一致
  TEST_APP_SECRET = 'cff054d1d7c84036a3dc160f9457e5f423704b15'.freeze
  TEST_PFX_PASSWORD = 'test-pass'.freeze

  class << self
    # 内存生成 RSA 密钥对 + 自签证书 + PKCS12，测试全程不依赖文件系统
    # 同一套密钥同时扮演合作方私钥和「农行公钥」，方便自签自验
    def keypair
      @keypair ||= begin
        key = OpenSSL::PKey::RSA.new(2048)
        cert = OpenSSL::X509::Certificate.new
        cert.version = 2
        cert.serial = 1
        cert.subject = OpenSSL::X509::Name.parse('/CN=abcbank-sdk-test/O=Test')
        cert.issuer = cert.subject
        cert.public_key = key.public_key
        cert.not_before = Time.now - 3600
        cert.not_after = Time.now + 365 * 24 * 3600
        cert.sign(key, OpenSSL::Digest::SHA256.new)
        [key, cert]
      end
    end

    def pfx_content
      key, cert = keypair
      OpenSSL::PKCS12.create(TEST_PFX_PASSWORD, 'test', key, cert).to_der
    end

    def cert_content
      keypair[1].to_der
    end
  end

  def build_api(options = {})
    Abcbank::Api.new({
      app_id: TEST_APP_ID,
      app_secret: TEST_APP_SECRET,
      pfx_content: AbcbankTestHelper.pfx_content,
      pfx_password: TEST_PFX_PASSWORD,
      abc_cert_content: AbcbankTestHelper.cert_content
    }.merge(options))
  end

  # 以「农行」身份构造一个已签名（可含加密业务数据）的响应报文
  def build_signed_response(api, biz_data: nil, code: '0000', msg: 'success', responseid: 'resp-001')
    body = {
      'code' => code,
      'msg' => msg,
      'biz_content' => '',
      'biz_encrypt' => biz_data ? api.crypt.aes_encrypt(biz_data.to_json) : '',
      'responseid' => responseid
    }
    plaintext = Abcbank::Crypt.sign_plaintext(body)
    key, = AbcbankTestHelper.keypair
    digest = api.sign_type == 'HASHANDSHA256' ? Base64.strict_encode64(OpenSSL::Digest::SHA256.digest(plaintext)) : plaintext
    body.merge('sign' => Base64.strict_encode64(key.sign(OpenSSL::Digest::SHA256.new, digest)))
  end
end
