# LaunchKey

The passwordless user authentication gem for interacting with
[LaunchKey](https://launchkey.com/)'s REST API.

## Installation

Add this line to your application's Gemfile:

    gem 'launchkey'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install launchkey

## Configuration

Run the Rails generator:

    $ rails g launchkey:install

Or if using a different framework:

```ruby
require 'launchkey'

LaunchKey.configure do |config|
  config.domain      = 'http://youdomain.tld'
  config.app_id      = 1234567890
  config.app_secret  = 'abcdefghijklmnopqrstuvwyz'
  config.keypair     = File.read('path/to/rsa-keypair.pem')
  config.passphrase  = 'private key passphrase'
end
```

## Usage

### Authorization

Make an authorization request with the user's LaunchKey username:

```ruby
auth_request = LaunchKey.authorize('johnwayne')
# => "71xmyusohv0171fg..."
```

The returned string is needed for continuing as well as terminating the
authorization. After the authorization request is made, the user is responsible
for either accepting or rejecting the authorization. To continue the process,
you must poll until a Hash containing the final `auth` payload is returned:

```ruby
auth_response = LaunchKey.poll_request(auth_request)
# => { "message": "Pending response", ... }

auth_response = LaunchKey.poll_request(auth_request)
# => { "auth" => "...", "user_hash": "..." }
```

Check if the client accepted or rejected the authorization request:

```ruby
LaunchKey.authorized?(auth_response)
# => true
```

### Deauthorization

```ruby
LaunchKey.deauthorize(auth_request)
# => true
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
