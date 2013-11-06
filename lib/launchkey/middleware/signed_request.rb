require 'rack/utils'
require 'digest'
require 'base64'
require 'json'

module LaunchKey
  module Middleware
    ##
    # A request middleware for Faraday that signs requests before making calls
    # to LaunchKey's APIs.
    class SignedRequest < Faraday::Middleware

      ##
      # @return [Client]
      #   The LaunchKey API client.
      attr_reader :client

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

      def sign_request(env)
        client.ping

        if env[:method] == :get
          query = Rack::Utils.parse_nested_query(env[:url].query).symbolize_keys
          env[:url].query = Rack::Utils.build_nested_query(auth_params.merge(query))
        else
          env[:body] = auth_params.merge(env[:body])
        end
      end

      def auth_params
        secret_key = secret
        signature  = client.config.keypair.sign secret_key

        {
          app_key:    client.config.app_key.to_s,
          secret_key: Base64.strict_encode64(secret_key),
          signature:  Base64.strict_encode64(signature)
        }
      end

      def secret
        client.api_public_key.public_encrypt raw_secret
      end

      def raw_secret
        JSON.dump(
          secret:  client.config.secret_key,
          stamped: client.ping_timestamp
        )
      end
    end # Pinger
  end # Middleware
end # LaunchKey
