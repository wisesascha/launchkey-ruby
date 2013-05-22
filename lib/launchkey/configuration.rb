module LaunchKey
  class Configuration

    REQUIRED_OPTIONS = [:domain, :app_id, :app_secret, :private_key].freeze

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
    #   The application's private RSA key.
    attr_accessor :private_key

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
  end # Configuration
end # LaunchKey
