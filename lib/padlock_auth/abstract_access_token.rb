# frozen_string_literal: true

module PadlockAuth
  # @abstract
  #
  # AbstractAccessToken is a base class for all access token classes.
  #
  # It provides all methods that are required for an access token to be
  # compatible with PadlockAuth.
  #
  # All implemented methods will default to returning false or nil, so that
  # any authentication/authorisation attempt will fail unless the methods are implemented.
  class AbstractAccessToken
    # Indicates if token is acceptable for specific scopes.
    #
    # @param scopes [Array<String>] scopes
    #
    # @return [Boolean] true if record is accessible and includes scopes, or false in other cases
    #
    def acceptable?(scopes)
      accessible? && includes_scope?(scopes)
    end

    # Indicates the access token matches the specific criteria of the strategy to
    # be considered a valid access token.
    #
    # Tokens failing to be accessible will be rejected as an invalid grant request,
    # with a 401 Unauthorized response.
    #
    # @abstract Implement this method in your access token class
    #
    # @return [Boolean] true if the token is accessible, false otherwise
    #
    def accessible?
      Kernel.warn "[PADLOCK_AUTH] #accessible? not implemented for #{self.class}"
      false
    end

    # Provides a lookup key for the reason the token is invalid.
    #
    # Messages will use the i18n scope `padlock_auth.errors.messages.invalid_token`,
    # with the default key of :unknown, providing a generic error message.
    #
    # @return [Symbol] the reason the token is invalid
    #
    def invalid_token_reason
      :unknown
    end

    # Indicates if the token includes the required scopes/audience.
    #
    # Tokens failing to include the required scopes will be rejected as an invalid scope request,
    # with a 403 Forbidden response.
    #
    # @abstract Implement this method in your access token class
    #
    # @param _required_scopes [Boolean] true if the token includes the required scopes, false otherwise
    #
    def includes_scope?(_required_scopes)
      Kernel.warn "[PADLOCK_AUTH] #includes_scope? not implemented for #{self.class}"
      false
    end

    # Provides a lookup key for the reason the token is forbidden.
    #
    # Messages will use the i18n scope `padlock_auth.errors.messages.forbidden_token`,
    # with the default key of :missing_scope, providing a generic error message.
    #
    # The required scopes are passed as an argument to the i18n for some user feedback as required.
    #
    # @return [Symbol] the reason the token is forbidden
    #
    def forbidden_token_reason
      :unknown
    end
  end
end
