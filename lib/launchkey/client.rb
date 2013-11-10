module LaunchKey
  ##
  # Handles general API actions:
  #
  # * Authorization
  # * Polling
  # * Validation
  # * Deorbit
  class Client
    include Requests

    ##
    # @return [Config]
    #   The client configuration.
    attr_reader :config

    ##
    # Initializes a new `Client` with optionally supplied `config` and
    # `options`. If no `config` is supplied, a clone of {LaunchKey.config}
    # is used.
    #
    # @param [Configuration] config
    #   The configuration to use.
    #
    # @param [{Symbol => Object}] options
    #   Configuration options to override.
    def initialize(config = LaunchKey.config.dup, options = {})
      @config = config
      @config.merge! options
    end

    ##
    # Starts the authorization process for the supplied `username`.
    #
    # @example Start authorization for a user.
    #     auth_request = LaunchKey.authorize 'bill'
    #     # => "lyyk9ai..."
    #
    # @param [String] username
    #   Username of LaunchKey user to authenticate.
    #
    # @return [String]
    #   An authorization request token.
    def authorize(username)
      post('auths', username: username).body['auth_request']
    end

    ##
    # Checks the status of the authorization process for the supplied
    # `auth_request` (returned by {#authorize}).
    #
    # @example Poll an auth request.
    #     auth_request = LaunchKey.authorize('bob')
    #
    #     until response = LaunchKey.poll_request(auth_request)
    #       # Check periodically until a response is given
    #       sleep 1
    #     end
    #
    #     # Move on to check the response...
    #
    # @param [String] auth_request
    #   The authorization request token to check.
    #
    # @return [{String => String}]
    #   The response
    def poll_request(auth_request)
      get('poll', auth_request: auth_request).body.with_indifferent_access
    rescue Errors::AuthRequestPendingError
      false
    end

    alias poll poll_request

    ##
    # Checks whether the user accepted or declined authorization in an auth
    # response returned by {#poll_request}.
    #
    # @example Checking authorization.
    #
    #     response = LaunchKey.poll_request(auth_request)
    #
    #     if authorized?(response['auth'])
    #       # User allowed the request
    #     else
    #       # User declined the request
    #     end
    #
    # @param [String] auth_response
    #   The auth response to validate.
    #
    # @return [true, false]
    #   Whether the authorization attempt was allowed or denied.
    def authorized?(auth_response)
      auth = load_auth(auth_response)

      if valid_auth?(auth)
        notify :authenticate, true, auth[:auth_request]
      else
        notify :authenticate, false, auth[:auth_request]
      end
    end

    ##
    # Verifies the authenticity of a webook request from LaunchKey, returning
    # the `user_hash` if successful.
    #
    # @param [{Symbol => String}] params
    #   Parameters supplied by LaunchKey in webhook request.
    #
    # @return [String, nil]
    #   The user hash when request is valid, `nil` otherwise
    def deorbit(params)
      signature = Base64.decode64(params[:signature])

      unless api_public_key.verify(signature, params[:deorbit])
        logger.debug 'Deorbit request failed: Signature mismatch'
        # TODO: Consider raising an error for easier handling in rescue_from
        return
      end

      payload   = JSON.parse(params[:deorbit]).with_indifferent_access
      timestamp = Time.parse(payload[:launchkey_time])

      timestamp -= ping_difference
      logger.debug "Deorbit received with timestamp #{timestamp}"

      # TODO: Consider raising a WebhookTimeoutError
      timestamp > 5.minutes.ago and payload[:user_hash]
    end

    ##
    # Notifies LaunchKey to confirm that the user's session has ended.
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
