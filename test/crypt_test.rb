require 'test_helper'

class CryptTest < Minitest::Test
  include AbcbankTestHelper

  def setup
    @api = build_api
    @crypt = @api.crypt
  end

  def test_aes_roundtrip
    plaintext = { 'data' => { 'accName' => '测试户名', 'accNo' => '02180401040000020' } }.to_json
    encrypted = @crypt.aes_encrypt(plaintext)

    refute_includes encrypted, "\n"
    assert_equal plaintext, @crypt.aes_decrypt(encrypted)
  end

  def test_aes_uses_first_24_chars_as_key_and_last_16_as_iv
    encrypted = @crypt.aes_encrypt('hello')

    cipher = OpenSSL::Cipher.new('aes-192-cbc')
    cipher.decrypt
    cipher.key = TEST_APP_SECRET[0, 24]
    cipher.iv = TEST_APP_SECRET[24, 16]
    assert_equal 'hello', cipher.update(Base64.decode64(encrypted)) + cipher.final
  end

  def test_aes_rejects_invalid_app_secret_length
    api = build_api(app_secret: 'too-short')
    assert_raises(Abcbank::ConfigError) { api.crypt.aes_encrypt('x') }
  end

  def test_aes_decrypt_error
    assert_raises(Abcbank::DecryptError) { @crypt.aes_decrypt(Base64.strict_encode64('not-cipher-data!')) }
  end

  def test_sign_plaintext_sorts_keys_and_joins_values_with_at
    envelope = {
      'appid' => 'my-appid',
      'sign_type' => 'SHA256',
      'encrypt_type' => 'AES',
      'encrypt_data' => 'CIPHER==',
      'biz_data' => '',
      'nonce' => 'abc123',
      'timestamp' => '2021-12-28 16:21:39'
    }
    # 排序后 key 顺序: appid, encrypt_data, encrypt_type, nonce, sign_type, timestamp
    assert_equal 'my-appid@CIPHER==@AES@abc123@SHA256@2021-12-28 16:21:39',
                 Abcbank::Crypt.sign_plaintext(envelope)
  end

  def test_sign_plaintext_excludes_sign_code_msg_case_insensitively
    hash = { 'Sign' => 'x', 'CODE' => '0000', ' msg ' => 'ok', 'biz_encrypt' => 'DATA', 'responseid' => 'r1' }
    assert_equal 'DATA@r1', Abcbank::Crypt.sign_plaintext(hash)
  end

  def test_sign_and_verify_roundtrip_sha256
    plaintext = 'appid@DATA@AES@nonce@SHA256@2021-12-28 16:21:39'
    signature = @crypt.sign(plaintext)

    refute_includes signature, "\n"
    assert @crypt.verify(plaintext, signature)
  end

  def test_sign_and_verify_roundtrip_hashandsha256
    api = build_api(sign_type: 'HASHANDSHA256')
    plaintext = 'appid@DATA@AES@nonce@HASHANDSHA256@2021-12-28 16:21:39'
    signature = api.crypt.sign(plaintext)

    assert api.crypt.verify(plaintext, signature)
    # HASHANDSHA256 的签名与直接 SHA256 加签不同（先哈希再签）
    refute_equal @crypt.sign(plaintext), signature
  end

  def test_verify_detects_tampering
    signature = @crypt.sign('original text')
    refute @crypt.verify('tampered text', signature)
  end

  def test_missing_pfx_raises_config_error
    api = Abcbank::Api.new(
      app_id: TEST_APP_ID, app_secret: TEST_APP_SECRET,
      pfx_content: 'placeholder', abc_cert_content: AbcbankTestHelper.cert_content
    )
    assert_raises(OpenSSL::PKCS12::PKCS12Error) { api.crypt.sign('x') }
  end

  # 设置 ABC_PFX_PASSWORD=111111 时，用 docs 里的真实测试证书验证加载链路
  def test_real_certs_from_docs
    password = ENV['ABC_PFX_PASSWORD']
    skip 'set ABC_PFX_PASSWORD to run against real certs in docs/' unless password

    api = build_api(
      pfx_path: File.expand_path('../docs/certs/ABC_OpenBank_ThridPart_Test.pfx', __dir__),
      pfx_content: nil,
      pfx_password: password,
      abc_cert_path: File.expand_path('../docs/certs/ABC_Openbank_Sandbox.cer', __dir__),
      abc_cert_content: nil
    )
    signature = api.crypt.sign('smoke test plaintext')
    assert signature.length > 300
  end
end
