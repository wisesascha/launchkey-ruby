module LaunchKey
  module Middleware
    class RaiseErrors < Faraday::Response::Middleware

      SUCCESS_CODES = 200..399

      def call(env)
        response = @app.call(env)
        response.on_complete do |env|
          if error?(response)
            compose_error(response)
          end
        end
        response
      end

      private

      def error?(response)
        !SUCCESS_CODES.include?(response.status) || unsuccessful?(response.body)
      end

      def unsuccessful?(body)
        body.is_a?(::Hash) && body.has_key?('successful') &&
          !response.body['successful']
      end

      def compose_error(response)
        case response.body
        when ::Hash
          raise Errors::APIError.new(
            response.body['message'], response.body['message_code'], response
          )
        else
          raise Errors::APIError.new(
            'Unknown error', nil, response
          )
        end
      end
    end # RaiseErrors
  end # Middleware
end # LaunchKey
