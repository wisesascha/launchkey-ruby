module LaunchKey
  module Errors
    class InvalidKeypair < LaunchKeyError

      attr_reader :original_exception

      def initialize(original_exception)
        @original_exception = original_exception

        super(
          compose_message(
            'invalid_keypair', original_exception: original_exception
          )
        )
      end
    end # InvalidKeypair
  end # Errors
end # LaunchKey
