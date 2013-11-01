require 'faraday'
require 'faraday_middleware'
require 'launchkey/middleware'

module LaunchKey
  module Requests
    extend ActiveSupport::Concern

    included do
      delegate :get, :post, :put, :delete, :patch, to: :connection

      attr_accessor :ping_timestamp
    end

    def connection
      @connection ||= Faraday.new config.endpoint, connection_options do |conn|
        conn.use Middleware::RaiseErrors
        conn.use Middleware::Ping, self

        conn.request  :url_encoded
        conn.response :json, content_type: /\bjson$/

        if LaunchKey.debug?
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
