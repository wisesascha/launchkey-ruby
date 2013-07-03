require 'openssl'
require 'base64'
require 'digest'

module LaunchKey
  ##
  # Wraps `OpenSSL::PKey::RSA` to add convenience methods and extend
  # functionality of encryption/decryption methods:
  #
  # * OAEP is used over the default padding scheme in {#public_encrypt} and
  #   {#private_decrypt}.
  # * {#to_pem} defaults to using 256-bit AES encryption when a passphrase is
  #   supplied.
  # * {#fingerprint} and {#inspect} make debugging easier and more informative.
  # * {#sign} and {#verify} default to using 256-bit SHA-1 as the
  #   digest algorithm.
  # * Everything else is delegated, untouched to the original keypair
  #   in {#method_missing}.
  class RSAKey

    ##
    # Shortcut for OpenSSL SHA-2 256-bit digest algorithm.
    SHA256 = OpenSSL::Digest::SHA256

    ##
    # Shortcut for OpenSSL MD5 digest algorithm.
    MD5 = OpenSSL::Digest::MD5

    ##
    # Shortcut for RSA public-key algorithm.
    RSA = OpenSSL::PKey::RSA

    ##
    # Shortcut for PKCS#1 OAEP padding scheme.
    PKCS1_OAEP_PADDING = OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING

    ##
    # Regular expression matching unneeded header, footer, and line breaks of
    # public keys.
    PUBKEY_PATTERN = %r{(-{5}(BEGIN|END) PUBLIC KEY-{5}|\n)}

    ##
    # Generates a new keypair of supplied length in bits.
    #
    # @param [Fixnum] bits
    #   Key length in bits to generate (defaults to 2048 bits).
    #
    # @return [RSAKey]
    #   The generated keypair.
    def self.generate(bits = 2048)
      new RSA.new(bits)
    end

    ##
    # @return [RSA]
    #   The unwrapped RSA keypair instance.
    #
    # @api private
    attr_reader :key

    ##
    # Initializes a new `RSAKey` with supplied `key`.
    #
    # @param [RSA, String] key
    #   The {RSA} instance or PEM-formatted keypair to use.
    #
    # @param [{Symbol => Object}] options
    #   Additional options.
    #
    # @option options [String] :passphrase
    #   The keypair passphrase, if any.
    #
    # @option options [true, false] :public_only
    #   When `true`, supplied key is unwrapped with {.unwrap_public_key}.
    #
    # @raise [Errors::PrivateKeyMissing]
    #   When a `:passphrase` is supplied but incorrect, or private key
    #   is missing for some other reason.
    #
    # @raise [Errors::InvalidKeypair]
    #   When supplied `key` is malformed or in some way invalid.
    def initialize(key, options = {})
      @key = if key.is_a?(RSA)
        key
      elsif options[:public_only]
        RSA.new self.class.unwrap_public_key(key)
      else
        RSA.new key, options[:passphrase]
      end

      if options[:passphrase] && !private?
        raise Errors::PrivateKeyMissing
      end
    rescue OpenSSL::PKey::RSAError
      raise Errors::InvalidKeypair, $!
    end

    def public_key
      self.class.new key.public_key
    end

    def raw_public_key
      self.class.unwrap_public_key(key.public_key.to_pem)
    end

    def private_decrypt(data, padding = PKCS1_OAEP_PADDING)
      key.private_decrypt data, padding
    end

    def public_encrypt(data, padding = PKCS1_OAEP_PADDING)
      key.public_encrypt data, padding
    end

    ##
    # Signs supplied `data` with optionally supplied digest.
    #
    # @example
    #     data = 'sign me!'
    #     key = RSAKey.generate
    #     signature = key.sign(data)
    #
    # @param [string] data
    #   The data to sign.
    #
    # @param [OpenSSL::Digest] digest
    #   The digest to sign with, (defaults to `OpenSSL::Digest::SHA256`).
    #
    # @return [String]
    #   The signature.
    def sign(data, digest = SHA256.new)
      key.sign digest, data
    end

    ##
    # Verifies supplied `data` with optionally supplied digest.
    #
    # @example
    #     data = 'sign me!'
    #     key = RSAKey.generate
    #     signature = key.sign(data)
    #     pub_key = key.public_key
    #     puts pub_key.verify(signature, data) # => true
    #
    # @param [String] signature
    #   The signature to verify.
    #
    # @param [String] data
    #   The data to verify.
    #
    # @param [OpenSSL::Digest] digest
    #   The digest to verify with, (defaults to `OpenSSL::Digest::SHA256`).
    #
    # @return [true, false]
    #   `true` if signature is valid, `false` if signature is invalid.
    def verify(signature, data, digest = SHA256.new)
      key.public_key.verify digest, signature, data
    end

    ##
    # Check if supplied `object`'s public key fingerprint is identical to this
    # object's public key fingerprint.
    #
    # @param [RSAKey] other
    #   Other object to check.
    #
    # @return [true, false]
    #   `true` if fingerprints are identical, `false` otherwise.
    def ==(other)
      return false unless other.is_a?(RSAKey)
      fingerprint == other.fingerprint
    end

    ##
    # Returns a 128-bit MD5 fingerprint commonly used with SSH keys for
    # identifying the keypair.
    #
    # @example Get the fingerprint of a keypair.
    #     keypair.fingerprint
    #     # => "0a:a8:30:97:88:0c:11:90:1d:fd:fa:69:cc:31:6c:2b"
    #
    # @return [String]
    #   Fingerprint of public key.
    def fingerprint
      @fingerprint ||= MD5.hexdigest(raw_public_key).scan(/../).join(':')
    end

    ##
    # Returns information about the keypair.
    #
    # @example
    #     keypair.inspect
    #     # => "#<LaunchKey::RSAKey 0a:a8:30:97:88:0c:11:90:1d:fd:fa:69:cc:31:6c:2b>"
    #
    # @return [String]
    #   Inspection of keypair.
    def inspect
      "#<#{self.class.name} #{fingerprint}>"
    end

    def to_pem(passphrase = nil, cipher = 'AES-256-CBC')
      pem = []

      if private?
        pem << if passphrase.present?
          key.to_pem OpenSSL::Cipher.new(cipher), passphrase
        else
          key.to_pem
        end
      end

      pem << key.public_key.to_pem
      pem.join
    end

    alias to_s   to_pem
    alias export to_pem

    def method_missing(method_name, *args, &block)
      key.respond_to?(method_name) ? key.send(method_name, *args, &block) : super
    end

    def respond_to_missing?(method_name, include_private = false)
      key.respond_to?(method_name, include_private) || super
    end

    def respond_to?(method_name, include_private = false)
      key.respond_to?(method_name, include_private) || super
    end

    protected

    def self.unwrap_public_key(key)
      Base64.decode64 key.gsub(PUBKEY_PATTERN, '')
    end
  end # RSAKey
end # LaunchKey
