require 'test_helper'

class RequestTest < Minitest::Test
  include AbcbankTestHelper

  ENDPOINT = "#{Abcbank::TEST_URL}/openabc/api/enterpriseaccount/applyauthorization/v1".freeze

  def setup
    @api = build_api
  end

  def test_envelope_format_and_signature
    captured = nil
    stub_request(:post, ENDPOINT)
      .with { |req| captured = JSON.parse(req.body) }
      .to_return(status: 200, body: build_signed_response(@api).to_json)

    @api.enterprise_account.apply_authorization({ data: { accNo: '123' } })

    assert_equal TEST_APP_ID, captured['appid']
    assert_equal 'SHA256', captured['sign_type']
    assert_equal 'AES', captured['encrypt_type']
    assert_equal '', captured['biz_data']
    assert_match(/\A[0-9a-f]{32}\z/, captured['nonce'])
    assert_match(/\A\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\z/, captured['timestamp'])

    # encrypt_data 可解密回业务报文
    assert_equal({ 'data' => { 'accNo' => '123' } }, JSON.parse(@api.crypt.aes_decrypt(captured['encrypt_data'])))

    # sign 可以用自己的证书验回（测试里合作方与农行是同一套密钥）
    plaintext = Abcbank::Crypt.sign_plaintext(captured.reject { |k, _| k == 'sign' })
    assert @api.crypt.verify(plaintext, captured['sign'])
  end

  def test_response_verify_and_decrypt
    biz = { 'data' => { 'batNo' => 'B202608220001' }, 'resCode' => '0' }
    stub_request(:post, ENDPOINT)
      .to_return(status: 200, body: build_signed_response(@api, biz_data: biz).to_json)

    result = @api.enterprise_account.apply_authorization({ data: {} })

    assert result.success?
    assert_equal '0000', result.code
    assert_equal biz, result.data
    assert_equal 'resp-001', result.responseid
  end

  def test_bad_response_signature_raises
    body = build_signed_response(@api)
    body['sign'] = Base64.strict_encode64('forged-signature')
    stub_request(:post, ENDPOINT).to_return(status: 200, body: body.to_json)

    assert_raises(Abcbank::SignatureVerificationError) do
      @api.enterprise_account.apply_authorization({ data: {} })
    end
  end

  def test_missing_response_signature_raises
    body = build_signed_response(@api)
    body.delete('sign')
    stub_request(:post, ENDPOINT).to_return(status: 200, body: body.to_json)

    assert_raises(Abcbank::SignatureVerificationError) do
      @api.enterprise_account.apply_authorization({ data: {} })
    end
  end

  def test_verify_can_be_disabled
    body = build_signed_response(@api)
    body['sign'] = Base64.strict_encode64('forged-signature')
    stub_request(:post, ENDPOINT).to_return(status: 200, body: body.to_json)

    Abcbank.config.verify_response_sign = false
    result = @api.enterprise_account.apply_authorization({ data: {} })
    assert result.success?
  ensure
    Abcbank.config.verify_response_sign = nil
  end

  def test_http_403_raises_rate_limited
    stub_request(:post, ENDPOINT).to_return(status: 403, body: 'limited')

    error = assert_raises(Abcbank::RateLimitedError) do
      @api.enterprise_account.apply_authorization({ data: {} })
    end
    assert_equal 403, error.status
  end

  def test_http_500_raises_http_error
    stub_request(:post, ENDPOINT).to_return(status: 500, body: 'boom')

    error = assert_raises(Abcbank::HttpError) do
      @api.enterprise_account.apply_authorization({ data: {} })
    end
    assert_equal 500, error.status
  end

  def test_custom_headers_passthrough
    stub_request(:post, ENDPOINT)
      .with(headers: { 'openabc-AccExtension-busCode' => 'E0-6100-01', 'Content-Type' => 'application/json' })
      .to_return(status: 200, body: build_signed_response(@api).to_json)

    result = @api.enterprise_account.apply_authorization({ data: {} }, { 'openabc-AccExtension-busCode' => 'E0-6100-01' })
    assert result.success?
  end

  def test_all_api_methods_hit_expected_paths
    paths = {
      -> { @api.enterprise_account.query_state_info } => 'enterpriseaccount/querystateinfo',
      -> { @api.enterprise_payment.online_pay } => 'enterprisepayment/onlinepay',
      -> { @api.enterprise_payment.online_pay_state_qry } => 'enterprisepayment/onlinepaystateqry',
      -> { @api.enterprise_payment.push_single_transfer } => 'enterprisepayment/pushsingletransfer',
      -> { @api.enterprise_payment.query_single_state } => 'enterprisepayment/querysinglestate',
      -> { @api.digital_currency.insert_authorization_info } => 'digitalcurrencyyunlian/insertauthorizationinfo',
      -> { @api.digital_currency.query_authorization_info } => 'digitalcurrencyyunlian/queryauthorizationinfo',
      -> { @api.digital_currency.pre_entry_transfer } => 'digitalcurrencyyunlian/preentrytransfer',
      -> { @api.digital_currency.query_history_list } => 'digitalcurrencyyunlian/queryhistorylist',
      -> { @api.digital_currency.query_trade_detail } => 'digitalcurrencyyunlian/querytradedetail'
    }

    paths.each do |call, path|
      stub = stub_request(:post, "#{Abcbank::TEST_URL}/openabc/api/#{path}/v1")
             .to_return(status: 200, body: build_signed_response(@api).to_json)
      call.call
      assert_requested(stub)
    end
  end
end
