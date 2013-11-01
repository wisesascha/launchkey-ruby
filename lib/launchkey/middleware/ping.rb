require 'rack/utils'
require 'digest'
require 'base64'
require 'json'

module LaunchKey
  module Middleware
    class Ping < Faraday::Middleware

      PING_PATH = '/v1/ping'.freeze

      LOCK = Mutex.new

      def initialize(app, client)
        super(app)
        @client = client
      end

      def call(env)
        unless ping_request?(env)
          sign_request(env)
        end

        @app.call(env)
      end

      private

      def ping_request?(env)
        env[:url].path == PING_PATH && env[:method] == :get
      end

      def ping
        return if @client.config.api_public_key && @ping_timestamp

        response = @client.get PING_PATH
        update_api_public_key response.body
        update_ping_timestamp response.body
      end

      def ping_timestamp
        @ping_timestamp = Time.at(Time.now.to_f - @ping_difference.to_f + @ping_timestamp.to_f)
        @ping_timestamp.strftime('%Y-%m-%d %H:%M:%S')
      end

      def sign_request(env)
        ping

        if env[:method] == :get
          query = Rack::Utils.parse_nested_query(env[:url].query).symbolize_keys
          env[:url].query = Rack::Utils.build_nested_query(auth_params.merge(query))
        else
          env[:body] = auth_params.merge(env[:body])
        end
      end

      def auth_params
        secret_key = secret
        signature  = @client.config.keypair.sign secret_key

        {
          app_key:    @client.config.app_key.to_s,
          secret_key: Base64.strict_encode64(secret_key),
          signature:  Base64.strict_encode64(signature)
        }
      end

      def secret
        @client.config.api_public_key.public_encrypt raw_secret
      end

      def raw_secret
        JSON.dump secret: @client.config.secret_key, stamped: ping_timestamp
      end

      def update_ping_timestamp(body)
        @ping_timestamp  = Time.parse body['launchkey_time']
        @ping_difference = Time.now
      end

      def update_api_public_key(body)
        @client.config.api_public_key = body['key']
      end
    end # Pinger
  end # Middleware
end # LaunchKey
