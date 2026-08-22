module Abcbank
  module Apis
    module DigitalCurrency
      # 云联授权信息录入(数币)
      def insert_authorization_info(payload = {}, headers = {})
        post 'digitalcurrencyyunlian/insertauthorizationinfo', payload, headers
      end

      # 云联授权状态查询(数币)
      def query_authorization_info(payload = {}, headers = {})
        post 'digitalcurrencyyunlian/queryauthorizationinfo', payload, headers
      end

      # 对公钱包转账预录入(数币)
      def pre_entry_transfer(payload = {}, headers = {})
        post 'digitalcurrencyyunlian/preentrytransfer', payload, headers
      end

      # 对公钱包交易历史列表查询(数币)
      def query_history_list(payload = {}, headers = {})
        post 'digitalcurrencyyunlian/queryhistorylist', payload, headers
      end

      # 对公钱包交易详情获取(数币)
      def query_trade_detail(payload = {}, headers = {})
        post 'digitalcurrencyyunlian/querytradedetail', payload, headers
      end
    end
  end
end
