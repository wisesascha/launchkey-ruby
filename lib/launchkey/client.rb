module LaunchKey
  class Client
    include Requests

    ##
    # @return [Config]
    #   The client configuration.
    attr_reader :config

    def initialize(config = nil, options = {})
      @config = config || LaunchKey.config.dup
      @config.merge! options
    end

    ##
    # Starts the authorization process for the supplied `username`.
    #
    # @param [String] username
    #
    # @return [String]
    #   An authorization request token.
    def authorize(username)
      post('auths', username: username).body['auth_request']
    end

    def poll_request(auth_request)
      get('poll', auth_request: auth_request).body
    end

    def authorized?(auth_response)
      auth = load_auth(auth_response)

      if valid_auth?(auth)
        notify :authenticate, true, auth[:auth_request]
      else
        notify :authenticate, false
      end
    end

    def deorbit(orbit, signature)
      raise NotImplementedError
    end

    def deauthorize(auth_request)
      notify :revoke, true, auth_request
    end

    def valid_pins?(pins, device)
      raise NotImplementedError
    end

    private

    def notify(action, status, auth_request = nil)
      response = put('logs', action: action.to_s.capitalize, status: status, auth_request: auth_request).body
      response['message'] == 'Successfully updated' ? status : false
    end

    def valid_auth?(auth)
      auth[:response].downcase == 'true' && auth[:auth_request].present?
    end

    def load_auth(crypted_auth)
      JSON.load(decrypt_auth(crypted_auth)).with_indifferent_access
    end

    def decrypt_auth(crypted_auth)
      config.keypair.private_decrypt Base64.decode64(crypted_auth)
    end
  end # Client
end # LaunchKey
