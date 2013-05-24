require 'active_support/string_inquirer'
require 'openssl'

module LaunchKey
  class Configuration

    REQUIRED_OPTIONS = [:domain, :app_id, :app_secret, :keypair].freeze

    ##
    # @return [String]
    #   The domain and host of the application.
    attr_accessor :domain

    ##
    # @return [Integer]
    #   The application ID.
    attr_accessor :app_id

    ##
    # @return [String]
    #   The application secret.
    attr_accessor :app_secret

    ##
    # @return [String]
    #   The passphrase used to decrypt the {#keypair}
    attr_accessor :passphrase

    ##
    # @return [OpenSSL::PKey::RSA]
    #   The application's RSA keypair.
    #
    # @raise [Errors::Misconfiguration]
    #   When {#passphrase} is incorrect or `keypair` is malformed.
    def keypair
      return @keypair if @keypair

      unless @raw_keypair.present?
        raise Errors::Misconfiguration
      end

      begin
        @keypair = OpenSSL::PKey::RSA.new(@raw_keypair, passphrase)
      rescue OpenSSL::PKey::RSAError
        raise Errors::InvalidKeypair, $!
      end

      unless @keypair.private?
        raise Errors::PrivateKeyMissing
      end

      @keypair
    end

    ##
    # @param [String] value
    #   The application's RSA keypair.
    def keypair=(value)
      @keypair     = nil
      @raw_keypair = value
    end

    ##
    # Gets and sets Faraday middleware to be used in constructing a connection
    # to LaunchKey's API.
    #
    # @example Setting the request adapter.
    #     LaunchKey.config.middleware do |conn|
    #       conn.adapter :patron
    #     end
    #
    # @yieldparam [Faraday::Connection] conn
    #   The connection being constructed.
    #
    # @return [Proc]
    #   Faraday middleware.
    def middleware(&block)
      if block_given?
        @middleware = block
      else
        @middleware
      end
    end

    ##
    # @example Use staging API.
    #     LaunchKey.env.staging?
    #     # => false
    #
    #     LaunchKey.config.env = 'staging'
    #
    #     LaunchKey.env.staging?
    #     # => true
    #
    # @return [ActiveSupport::StringInquirer]
    #   The environment to use when making authorization requests, defaults
    #   to `production`.
    def env
      @env ||= ActiveSupport::StringInquirer.new('production')
    end

    ##
    # @param [String] value
    #   The environment to use when making authorization requests.
    def env=(value)
      @env = ActiveSupport::StringInquirer.new(value)
    end

    ##
    # @param [String] value
    #   LaunchKey's public RSA key.
    #
    # @api private
    def api_public_key=(value)
      @api_public_key = OpenSSL::PKey::RSA.new unwrap_public_key(value)
    end

    ##
    # @return [OpenSSL::PKey::RSA]
    #   LaunchKey's public RSA key.
    #
    # @api private
    attr_reader :api_public_key

    ##
    # Validate configuration and raise an error if any required options are
    # missing.
    #
    # @raise [Errors::Misconfiguration]
    #   When any of {REQUIRED_OPTIONS} are missing.
    #
    # @api private
    def validate!
      if REQUIRED_OPTIONS.collect { |opt| send(opt) }.any?(&:nil?)
        raise Errors::Misconfiguration
      end
    end

    private

    def unwrap_public_key(key)
      Base64.decode64 key.gsub("\n", '').gsub(/-----(BEGIN|END) PUBLIC KEY-----/, '')
    end
  end # Configuration
end # LaunchKey
