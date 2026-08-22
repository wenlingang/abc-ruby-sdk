require 'openssl'
require 'base64'

module Abcbank
  class Crypt
    SIGN_EXCLUDED_KEYS = %w[sign code msg].freeze

    attr_reader :client

    def initialize(client)
      @client = client
    end

    # 加签明文：剔除空值与 sign/code/msg 字段，按 key 字典序取「值」用 @ 连接
    # 与农行 Java SDK Utilities.getSignPlainText 一致
    def self.sign_plaintext(hash)
      hash.reject { |k, v| v.to_s.empty? || SIGN_EXCLUDED_KEYS.include?(k.to_s.strip.downcase) }
          .sort_by { |k, _| k.to_s }
          .map { |_, v| v.to_s }
          .join('@')
    end

    def aes_encrypt(plaintext)
      cipher = aes_cipher(:encrypt)
      Base64.strict_encode64(cipher.update(plaintext) + cipher.final)
    end

    def aes_decrypt(base64_text)
      cipher = aes_cipher(:decrypt)
      (cipher.update(Base64.decode64(base64_text)) + cipher.final).force_encoding(Encoding::UTF_8)
    rescue OpenSSL::Cipher::CipherError, ArgumentError => e
      raise DecryptError, "decrypt biz_encrypt failed: #{e.message}"
    end

    def sign(text)
      Base64.strict_encode64(private_key.sign(OpenSSL::Digest::SHA256.new, digest_for_sign(text)))
    end

    def verify(text, sign_base64)
      abc_public_key.verify(OpenSSL::Digest::SHA256.new, Base64.decode64(sign_base64), digest_for_sign(text))
    end

    private

    # HASHANDSHA256 时先对明文做 SHA256 摘要并 Base64，再进行 RSA 加签
    def digest_for_sign(text)
      return text unless client.sign_type == 'HASHANDSHA256'

      Base64.strict_encode64(OpenSSL::Digest::SHA256.digest(text))
    end

    # appSecret 固定 40 字符：前 24 字符为 AES-192 密钥，后 16 字符为 IV
    def aes_cipher(mode)
      secret = client.app_secret.to_s
      raise ConfigError, "app_secret 长度不正确，应为 40 字符" unless secret.length == 40

      cipher = OpenSSL::Cipher.new('aes-192-cbc')
      cipher.public_send(mode)
      cipher.key = secret[0, 24]
      cipher.iv = secret[24, 16]
      cipher
    end

    def private_key
      @private_key ||= begin
        content = client.pfx_content || (client.pfx_path && File.binread(client.pfx_path))
        raise ConfigError, "pfx_path/pfx_content 未配置" if content.nil?

        OpenSSL::PKCS12.new(content, client.pfx_password.to_s).key
      end
    end

    def abc_public_key
      @abc_public_key ||= begin
        content = client.abc_cert_content || (client.abc_cert_path && File.binread(client.abc_cert_path))
        raise ConfigError, "abc_cert_path/abc_cert_content 未配置" if content.nil?

        OpenSSL::X509::Certificate.new(content).public_key
      end
    end
  end
end
