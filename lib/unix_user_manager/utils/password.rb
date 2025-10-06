require 'securerandom'
require 'unix_crypt'

class UnixUserManager
  module Utils
    module Password
      def self.pick_encrypted(password:, encrypted_password:, salt:, algorithm:, default:)
        return encrypted_password unless encrypted_password.to_s.empty?
        return hash(password: password, algorithm: algorithm, salt: salt) unless password.to_s.empty?
        default
      end

      def self.hash(password:, algorithm: :sha512, salt: nil)
        raise ArgumentError, "password must be provided" if password.nil? || password.to_s.empty?

        salt ||= SecureRandom.hex(8)

        # Normalize algorithm input to support symbols, strings (e.g. "sha256", "sha-512"),
        # and numeric variants (e.g. "6" or 6) without silently defaulting to sha512.
        normalized = algorithm
        normalized = normalized.to_s if normalized.is_a?(Integer)
        normalized = normalized.to_s if !normalized.is_a?(String) && !normalized.is_a?(Symbol)
        normalized = normalized.to_s if normalized.is_a?(Symbol)
        normalized = normalized.downcase.gsub(/[^a-z0-9]/, '')

        algo_sym = case normalized
                   when 'sha512', '6' then :sha512
                   when 'sha256', '5' then :sha256
                   when 'md5',    '1' then :md5
                   else :sha512
                   end

        case algo_sym
        when :sha512
          UnixCrypt::SHA512.build(password, salt)
        when :sha256
          UnixCrypt::SHA256.build(password, salt)
        when :md5
          UnixCrypt::MD5.build(password, salt)
        else
          UnixCrypt::SHA512.build(password, salt)
        end
      end
    end
  end
end
