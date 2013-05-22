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

    def keypair=(value)
      @keypair = OpenSSL::PKey::RSA.new(value)
    end

    ##
    # @return [OpenSSL::PKey::RSA]
    #   The application's RSA keypair.
    attr_reader :keypair

    def api_public_key=(value)
      @api_public_key = OpenSSL::PKey::RSA.new unwrap_public_key(value)
    end

    ##
    # @return [OpenSSL::PKey::RSA]
    #   LaunchKey's public key.
    attr_reader :api_public_key

    ##
    # @return [String]
    #   The passphrase used to decrypt the {#private_key}
    attr_accessor :passphrase

    def middleware(&block)
      if block_given?
        @middleware = block
      else
        @middleware
      end
    end

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
