require 'securerandom'

FactoryGirl.define do
  sequence(:token) { SecureRandom.base64(32).gsub(/[^\d\w]/, '') }

  factory :configuration, aliases: [:config], class: LaunchKey::Configuration do
    skip_create

    domain      { Faker::Internet.http_url }
    app_id      { rand(1..9_999_999) }
    app_secret  { FactoryGirl.generate(:token) }
    private_key { SecureRandom.base64(512) }
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
