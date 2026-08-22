# Abcbank SDK

中国农业银行开放银行 API SDK for Ruby，实现「国际SDK」加密协议（AES-192-CBC 报文加解密 + SHA256withRSA 签名验签），覆盖云联授权、企业云联支付、数币钱包云联支付接口。

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'abcbank-sdk'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install abcbank-sdk

## Usage

### initialize

```ruby
# config/initializers/abcbank.rb

Abcbank.configure do |config|
  config.app_id = 'xxx'                                  # 开放银行分配的 APPID
  config.app_secret = 'xxx'                              # 40 字符加密串（AES 密钥+IV）
  config.pfx_path = '/path/to/partner.pfx'               # 合作方私钥证书
  config.pfx_password = 'xxx'                            # 私钥证书密码
  config.abc_cert_path = '/path/to/abc_public.cer'       # 农行公钥证书（响应验签用）
  config.api_base_url = Abcbank::TEST_URL                # 测试环境；生产用 Abcbank::PROD_URL
  # config.sign_type = 'SHA256'                          # 默认 SHA256；大报文可用 'HASHANDSHA256'
  # config.verify_response_sign = true                   # 默认开启响应验签
end
```

证书也支持直接传内容（例如从 ENV/密钥管理服务注入，不落盘）：

```ruby
Abcbank.configure do |config|
  config.pfx_content = Base64.decode64(ENV['ABC_PFX_BASE64'])
  config.pfx_password = ENV['ABC_PFX_PASSWORD']
  config.abc_cert_content = Base64.decode64(ENV['ABC_CERT_BASE64'])
end
```

```ruby
api = Abcbank::Api.new
```

```ruby
resp = api.enterprise_account.apply_authorization({
  data: {
    accNo: '02180401040000020',
    accName: 'XXX有限公司',
    accCur: '156',
    bsnCodList: ['E0-6100-01'],
    recDate: '20260822',
    channel: 'QD-0001',
    platform: 'XXX'
  }
})

resp.success?    # => code == '0000'
resp.code        # 网关返回码
resp.msg         # 返回码描述
resp.data        # 解密后的业务报文（Hash）
resp.data!       # 同 data，但失败时抛 Abcbank::ResultError
resp.responseid  # 响应日志号
resp.raw         # 完整响应信封
```

部分接口需要额外报文头（`openabc-AccExtension-*` 或 `openabc-Extension-*`），作为第二个参数传入：

```ruby
api.enterprise_payment.push_single_transfer(payload, {
  'openabc-Extension-reqDate' => '20260822',
  'openabc-Extension-reqTime' => '101130',
  'openabc-Extension-clientIP' => '40.123.23.23',
  'openabc-Extension-busCode' => 'E0-6100-01'
})
```

### 错误处理

| 异常 | 场景 |
| --- | --- |
| `Abcbank::AppNotConfigException` | app_id / app_secret / pfx 未配置 |
| `Abcbank::ConfigError` | app_secret 长度不是 40、证书缺失 |
| `Abcbank::RateLimitedError` | HTTP 403，被网关限流 |
| `Abcbank::HttpError` | 其他非 2xx 响应（`error.status` / `error.body`） |
| `Abcbank::SignatureVerificationError` | 响应报文验签失败 |
| `Abcbank::DecryptError` | 响应 biz_encrypt 解密失败 |
| `Abcbank::ResultError` | `data!` 且 code 非 '0000'（`error.code` / `error.msg`） |

## Apis

[查看全部接口](apis.md)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wenlingang/abc-ruby-sdk.
