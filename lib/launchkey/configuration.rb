require 'openssl'

module LaunchKey
  ##
  # Defines and validates configuration options for {LaunchKey::Client}.
  class Configuration

    OPTIONS = [:domain, :app_key, :secret_key, :keypair, :passphrase, :endpoint,
               :use_system_ssl_cert_chain, :http_open_timeout,
               :http_read_timeout, :debug].freeze

    REQUIRED_OPTIONS = [:domain, :app_key, :secret_key, :keypair].freeze

    ##
    # @return [String]
    #   The domain and host of the application.
    attr_accessor :domain

    ##
    # @return [Integer]
    #   The application key.
    attr_accessor :app_key

    ##
    # @return [String]
    #   The application secret.
    attr_accessor :secret_key

    ##
    # @return [String]
    #   The passphrase used to decrypt the {#keypair}
    attr_accessor :passphrase

    ##
    # @return [true, false]
    #   `true` to use whatever CAs OpenSSL has installed on your system, `false`
    #   to use the ca-bundle.crt file included in LaunchKey itself
    #   (reccomended and default).
    attr_accessor :use_system_ssl_cert_chain

    alias use_system_ssl_cert_chain? use_system_ssl_cert_chain

    ##
    # @return [Fixnum]
    #   The HTTP open timeout in seconds (defaults to 2).
    attr_accessor :http_open_timeout

    ##
    # @return [Fixnum]
    #   The HTTP read timeout in seconds (defaults to 5).
    attr_accessor :http_read_timeout

    ##
    # @return [true, false]
    #   `true` to log extra debug info, `false` to suppress.
    attr_accessor :debug

    alias debug? debug

    ##
    # Initializes a new `Configuration` with optionally supplied `options`.
    #
    # @param [{Symbol => Object}] options
    #   Configuration options to initialize with.
    def initialize(options = {})
      @use_system_ssl_cert_chain = false
      @http_open_timeout         = 2
      @http_read_timeout         = 5
      @debug                     = false

      update(options)
    end

    ##
    # Merges the supplied `options`, overwriting already set options.
    #
    # @param [{ Symbol => Object}] options
    #   The configuration options to set.
    #
    # @return [self]
    def update(options)
      options.each do |option, value|
        if OPTIONS.include? option.to_sym
          send :"#{option}=", value
        end
      end

      self
    end

    alias merge! update

    ##
    # @param [{ Symbol => Object}] options
    #   The configuration options to set.
    #
    # @return [Config]
    #   A new configuration merged with supplied `options`.
    def merge(options)
      dup.update(options)
    end

    ##
    # @return [{ Symbol => Object }]
    #   The configuration options as a `Hash`.
    def to_hash
      Hash[OPTIONS.collect { |option| [option, send(option)] }]
    end

    ##
    # @return [Logger]
    #   The logger.
    def logger
      @logger ||= (rails_logger || default_logger)
    end

    ##
    # @return [Logger]
    #   The logger.
    attr_writer :logger

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

      @keypair = RSAKey.new @raw_keypair, passphrase: passphrase
    end

    ##
    # @param [String] value
    #   The application's RSA keypair.
    def keypair=(value)
      if value.is_a?(RSAKey)
        @keypair = value
      else
        @keypair     = nil
        @raw_keypair = value
      end
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
    # @return [String]
    #   The LaunchKey API endpoint to make requests to, defaults to {ENDPOINT}.
    def endpoint
      @endpoint ||= ENDPOINT.dup
    end

    ##
    # @return [String]
    #   The LaunchKey API endpoint to make requests to.
    attr_writer :endpoint

    ##
    # @param [String] value
    #   LaunchKey's public RSA key.
    #
    # @api private
    def api_public_key=(value)
      @api_public_key = RSAKey.new value, public_only: true
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

    ##
    # @api private
    def ca_bundle_path
      if use_system_ssl_cert_chain? && File.exist?(OpenSSL::X509::DEFAULT_CERT_FILE)
        OpenSSL::X509::DEFAULT_CERT_FILE
      else
        local_cert_path
      end
    end

    ##
    # @api private
    def local_cert_path
      File.expand_path(File.join('..', '..', '..', 'resources', 'ca-bundle.crt'), __FILE__)
    end

    private

    def rails_logger
      defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
    end

    def default_logger
      Logger.new($stdout).tap do |logger|
        logger.level = Logger::INFO
      end
    end
  end # Configuration
end # LaunchKey
