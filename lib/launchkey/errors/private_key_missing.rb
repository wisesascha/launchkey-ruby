module LaunchKey
  module Errors
    class PrivateKeyMissing < LaunchKeyError

      def initialize
        super(
          compose_message(
            'private_key_missing'
          )
        )
      end
    end # PrivateKeyMissing
  end # Errors
end # LaunchKey
