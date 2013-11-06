require 'faraday'
require 'faraday_middleware'
require 'launchkey/middleware'

module LaunchKey
  ##
  # Shares behavior for making HTTP requests to LaunchKey.
  module Requests
    extend ActiveSupport::Concern

    included do
      delegate :get, :post, :put, :delete, :patch, to: :connection

      attr_reader :pinged_at
    end

    def api_public_key
      ping unless config.api_public_key
      config.api_public_key
    end

    def ping
      return if config.api_public_key && !ping?

      @pinged_at = Time.now

      response = get(PING_PATH)

      config.api_public_key = response.body['key']
      self.ping_time        = Time.parse(response.body['launchkey_time'])
    end

    def ping?
      !pinged_at || 5.minutes.ago > pinged_at
    end

    def ping_timestamp
      ping_time.strftime('%Y-%m-%d %H:%M:%S')
    end

    def ping_difference
      @ping_difference ||= 0
    end

    def ping_time
      Time.now + ping_difference
    end

    def ping_time=(time)
      @ping_difference = (time - Time.now).to_f

      logger.debug "LaunchKey time (#{time}) updated with a time difference of #{@ping_difference} seconds"

      @ping_difference
    end

    def logger
      config.logger
    end

    def connection
      @connection ||= Faraday.new config.endpoint, connection_options do |conn|
        conn.use Middleware::RaiseErrors
        conn.use Middleware::SignedRequest, self

        conn.request  :url_encoded
        conn.response :json, content_type: /\bjson$/

        if config.debug?
          conn.response :logger, config.logger
        end

        conn.adapter Faraday.default_adapter

        LaunchKey.middleware.try(:call, conn)
      end
    end

    private

    def connection_options
      {
        headers: {
          accept:     'application/json',
          user_agent: user_agent
        },
        request: {
          open_timeout: config.http_open_timeout,
          timeout:      config.http_read_timeout
        },
        ssl: {
          verify_mode: OpenSSL::SSL::VERIFY_PEER,
          ca_file:     config.ca_bundle_path
        }
      }
    end

    def user_agent
      'launchkey-ruby/%s (Rubygems; Ruby %s %s)' % [LaunchKey::VERSION, RUBY_VERSION, RUBY_PLATFORM]
    end
  end # Requests
end # LaunchKey
