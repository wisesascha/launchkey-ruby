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

    ##
    # Mapping of API error codes to
    API_ERRORS = Hash.new(APIError)

    # Make each error accessible as `LaunchKey::Errors::<ErrorName>` and add it
    # to `API_ERRORS` as `API_ERRORS[<code>]`.
    {
      # Auths
      40421 => :IncorrectDataError,
      40422 => :InvalidCredentialsError,
      40423 => :AppVerificationError,
      40424 => :NoPairedDevicesError,
      40425 => :InvalidAppKeyError,
      40426 => :UserNotFoundError,
      40428 => :SignatureMismatchError,
      40429 => :InvalidCredentialsError,
      40431 => :AuthExpiredError,
      # 40432 POST Error checking signature, ensure padding is valid
      # 40433 POST Signature matches, but error decrypting secret_key
      # 40434 POST Decrypted secret_key, but malformed structure
      40435 => :AppDisabledError,
      40436 => :AuthAttemptsExceededError,

      # Logs
      50441 => :IncorrectDataError,
      50442 => :InvalidCredentialsError,
      50443 => :AppVerificationError,
      50444 => :IncorrectDataError,
      50445 => :InvalidAppKeyError,
      # 50446 PUT Auth request does not correlate to session
      50447 => :AppNotFoundError,
      50448 => :SignatureMismatchError,
      50449 => :InvalidCredentialsError,
      50451 => :AuthExpiredError,
      # 50452 PUT Error checking signature, make sure padding is valid
      # 50453 PUT Signature matches, but error decrypting secret_key
      # 50454 PUT Decrypted secret_key, but malformed structure
      50455 => :LogInConsistencyError,
      50456 => :UnknownAuthRequestError,

      # Ping
      60401 => :IncorrectDataError,

      # Poll
      70401 => :IncorrectDataError,
      70402 => :AuthRequestNotFoundError,
      70403 => :AuthRequestPendingError,
      70404 => :AuthRequestExpiredError
    }.each do |code, error|
      klass = if Errors.const_defined?(error)
        Errors.const_get(error)
      else
        Errors.const_set error, Class.new(APIError)
      end

      API_ERRORS[code] = klass
    end
  end # Errors
end # LaunchKey
