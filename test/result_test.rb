require 'test_helper'

class ResultTest < Minitest::Test
  def test_success_when_code_is_0000
    result = Abcbank::Result.new({ 'code' => '0000', 'msg' => '交易成功' }, '{"a":1}')

    assert result.success?
    refute result.failure?
    assert_equal({ 'a' => 1 }, result.data)
    assert_equal({ 'a' => 1 }, result.data!)
  end

  def test_failure_and_data_bang_raises
    result = Abcbank::Result.new({ 'code' => '5001', 'msg' => '签名验签失败' }, nil)

    refute result.success?
    error = assert_raises(Abcbank::ResultError) { result.data! }
    assert_equal '5001', error.code
    assert_equal '签名验签失败', error.msg
  end

  def test_nil_safety
    result = Abcbank::Result.new(nil, nil)

    refute result.success?
    assert_equal '', result.code
    assert_equal '', result.msg
    assert_nil result.responseid
    assert_equal({}, result.data)
  end

  def test_non_json_biz_content_kept_as_raw
    result = Abcbank::Result.new({ 'code' => '0000' }, 'plain text body')
    assert_equal({ '_raw' => 'plain text body' }, result.data)
  end

  def test_response_id_fallback_on_error_field
    result = Abcbank::Result.new({ 'code' => '4004', 'response_id' => 'err-id' }, nil)
    assert_equal 'err-id', result.responseid
  end
end
