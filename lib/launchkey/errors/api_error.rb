module LaunchKey
  module Errors
    class APIError < LaunchKeyError

      ##
      # @return [String]
      #   The API error message.
      attr_reader :message

      ##
      # @return [Integer]
      #   The code of the error message.
      attr_reader :code

      ##
      # @return [Faraday::Response]
      #   The HTTP response that triggered the error.
      attr_reader :response

      def initialize(message, code = nil, response = nil)
        @message  = message
        @code     = code
        @response = response
      end

      def to_s
        "#{formatted_code}#{message}#{formatted_status}"
      end

      private

      def formatted_status
        response.respond_to?(:status) ? " (Status #{response.status})" : ""
      end

      def formatted_code
        code ? "[#{code}] " : ""
      end
    end # APIError
  end # Errors
end # LaunchKey
