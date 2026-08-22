module Abcbank
  module Apis
    module EnterpriseAccount
      # 云联业务授权申请
      def apply_authorization(payload = {}, headers = {})
        post 'enterpriseaccount/applyauthorization', payload, headers
      end

      # 云联授权状态查询
      def query_state_info(payload = {}, headers = {})
        post 'enterpriseaccount/querystateinfo', payload, headers
      end
    end
  end
end
