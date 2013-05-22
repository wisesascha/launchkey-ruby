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

```ruby
require 'launchkey'

LaunchKey.configure do |config|
  config.domain      = 'http://youdomain.tld'
  config.app_id      = 1234567890
  config.app_secret  = 'abcdefghijklmnopqrstuvwyz'
  config.private_key = File.read('path/to/key')
  config.passphrase  = 'private key passphrase'
end
```

## Usage

### Signing In

Make an authorization request with the user's LaunchKey username:

```ruby
request = LaunchKey.authorize(username)
# => #<LaunchKey::AuthorizationRequest token:"...">
```

The returned request object is responsible for continuing the authorization
process. After the authorization request is made, the user is responsible for
either accepting or rejecting the authorization. To continue the process, you
must poll until a response is given.

```ruby
until request.finished?
  request.poll
end

if request.success?
  # The request was accepted by the user.
  authorization = request.authorization
else
  # The request was rejected by the user.
end
```

### Signing Out

```ruby
authorization.destroy
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
