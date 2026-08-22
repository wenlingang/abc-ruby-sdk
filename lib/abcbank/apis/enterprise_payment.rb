module Abcbank
  module Apis
    module EnterprisePayment
      # 企业云联支付申请
      def online_pay(payload = {}, headers = {})
        post 'enterprisepayment/onlinepay', payload, headers
      end

      # 云联支付状态查询
      def online_pay_state_qry(payload = {}, headers = {})
        post 'enterprisepayment/onlinepaystateqry', payload, headers
      end

      # 单笔转账交易推送
      def push_single_transfer(payload = {}, headers = {})
        post 'enterprisepayment/pushsingletransfer', payload, headers
      end

      # 单笔转账交易推送状态查询
      def query_single_state(payload = {}, headers = {})
        post 'enterprisepayment/querysinglestate', payload, headers
      end
    end
  end
end
