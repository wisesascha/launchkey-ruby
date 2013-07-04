module LaunchKey
  module Errors
    class Misconfiguration < LaunchKeyError

      def initialize
        super(
          compose_message(
            'misconfiguration'
          )
        )
      end
    end # Misconfiguration
  end # Errors
end # LaunchKey
