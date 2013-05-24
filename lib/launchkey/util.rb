module LaunchKey
  module Util
    extend self

    def generate_rsa_keypair(options = {})
      options[:bits]   ||= 2048
      options[:cipher] ||= 'AES-256-CBC'

      keypair    = OpenSSL::PKey::RSA.new(options[:bits])
      public_key = keypair.public_key.to_pem

      private_key = if options[:passphrase].present?
        cipher = OpenSSL::Cipher.new(options[:cipher])
        keypair.to_pem(cipher, options[:passphrase])
      else
        keypair.to_pem
      end

      [private_key, public_key].join
    end
  end # Util
end # LaunchKey
