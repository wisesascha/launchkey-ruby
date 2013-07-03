require 'launchkey'
require 'securerandom'

module Launchkey
  module Generators
    class InstallGenerator < Rails::Generators::Base

      def self.source_root
        @_launchkey_source_root ||= File.expand_path('../../templates', __FILE__)
      end

      desc 'Creates a LaunchKey initializer and generates a keypair at config/launchkey_keypair.pem'

      def create_keypair
        @passphrase = random_passphrase
        @keypair    = LaunchKey::RSAKey.generate
        create_file 'config/launchkey_keypair.pem', @keypair.to_pem(@passphrase)
      end

      def copy_initializer
        template 'launchkey.rb', 'config/initializers/launchkey.rb'
      end

      def show_readme
        readme = File.join(self.class.source_root, 'README.tt')
        say ERB.new(File.binread(readme)).result(binding), :green
      end

      private

      def random_passphrase
        SecureRandom.base64(64).gsub(/[^a-z0-9]/i, '')
      end
    end # InstallGenerator
  end # Generators
end # LaunchKey
