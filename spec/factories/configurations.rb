require 'securerandom'

FactoryGirl.define do
  sequence(:token)   { SecureRandom.base64(32).gsub(/[^\d\w]/, '') }

  sequence(:keypair) { LaunchKey::RSAKey.generate.to_pem }

  sequence(:public_key) do
    pair = OpenSSL::PKey::RSA.new(1024)
    pair.public_key.to_pem
  end

  factory :configuration, aliases: [:config], class: LaunchKey::Configuration do
    skip_create

    domain      { Faker::Internet.http_url }
    app_id      { rand(1..9_999_999) }
    app_secret  { FactoryGirl.generate(:token) }
    keypair     { FactoryGirl.generate(:keypair) }
    passphrase  { FactoryGirl.generate(:token) }

    initialize_with do
      new.tap do |config|
        attributes.each do |attribute, value|
          config.send :"#{attribute}=", value
        end
      end
    end
  end
end
