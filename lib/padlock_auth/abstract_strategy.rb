module PadlockAuth
  # @abstract
  #
  # Abstract strategy for building and authenticating access tokens.
  #
  # Strategies are responsible for building access tokens and authenticating them.
  class AbstractStrategy
    # Build an access token from a raw token.
    #
    # @param _raw_token [String] The raw token
    #
    # @return [PadlockAuth::AbstractAccessToken, nil] The access token
    def build_access_token(_raw_token)
      Kernel.warn "[PADLOCK_AUTH] #build_access_token not implemented for #{self.class}"
      nil
    end

    # Build an access token from credentials.
    #
    # @param _username [String] The username
    # @param _password [String] The password
    #
    # @return [PadlockAuth::AbstractAccessToken, nil] The access token
    def build_access_token_from_credentials(_username, _password)
      Kernel.warn "[PADLOCK_AUTH] #build_access_token_from_credentials not implemented for #{self.class}"
      nil
    end

    # Build an invalid token response.
    #
    # Used to indicate that a token is invalid.
    #
    # @param access_token [PadlockAuth::AbstractAccessToken] The access token
    #
    # @return [PadlockAuth::Http::InvalidTokenResponse] The response
    def build_invalid_token_response(access_token)
      Http::InvalidTokenResponse.from_access_token(access_token)
    end

    # Build a forbidden token response.
    #
    # Used to indicate that a token does not have the required scopes.
    #
    # @param access_token [PadlockAuth::AbstractAccessToken] The access token
    # @param scopes [PadlockAuth::Config::Scopes] The required scopes
    #
    # @return [PadlockAuth::Http::ForbiddenTokenResponse] The response
    def build_forbidden_token_response(access_token, scopes)
      Http::ForbiddenTokenResponse.from_access_token(access_token, scopes)
    end
  end
end
