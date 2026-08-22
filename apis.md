# 企业用户认证（云联授权）

| 调用 | 描述 | 接口路径 |
| ------ | ----------- | -- |
| api.enterprise_account.apply_authorization | 云联业务授权申请 | openabc/api/enterpriseaccount/applyauthorization/v1 |
| api.enterprise_account.query_state_info | 云联授权状态查询 | openabc/api/enterpriseaccount/querystateinfo/v1 |

# 企业云联支付

| 调用 | 描述 | 接口路径 |
| ------ | ----------- | -- |
| api.enterprise_payment.online_pay | 企业云联支付申请 | openabc/api/enterprisepayment/onlinepay/v1 |
| api.enterprise_payment.online_pay_state_qry | 云联支付状态查询 | openabc/api/enterprisepayment/onlinepaystateqry/v1 |
| api.enterprise_payment.push_single_transfer | 单笔转账交易推送 | openabc/api/enterprisepayment/pushsingletransfer/v1 |
| api.enterprise_payment.query_single_state | 单笔转账交易推送状态查询 | openabc/api/enterprisepayment/querysinglestate/v1 |

# 数币钱包云联支付

| 调用 | 描述 | 接口路径 |
| ------ | ----------- | -- |
| api.digital_currency.insert_authorization_info | 云联授权信息录入(数币) | openabc/api/digitalcurrencyyunlian/insertauthorizationinfo/v1 |
| api.digital_currency.query_authorization_info | 云联授权状态查询(数币) | openabc/api/digitalcurrencyyunlian/queryauthorizationinfo/v1 |
| api.digital_currency.pre_entry_transfer | 对公钱包转账预录入(数币) | openabc/api/digitalcurrencyyunlian/preentrytransfer/v1 |
| api.digital_currency.query_history_list | 对公钱包交易历史列表查询(数币) | openabc/api/digitalcurrencyyunlian/queryhistorylist/v1 |
| api.digital_currency.query_trade_detail | 对公钱包交易详情获取(数币) | openabc/api/digitalcurrencyyunlian/querytradedetail/v1 |
