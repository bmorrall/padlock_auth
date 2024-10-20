module PadlockAuth
  module Token
    ##
    # Strategy for token-based authentication.
    #
    # This strategy compares a token from the request to a secret key.
    #
    # It does not allow for scopes, so it will always return false for any required scopes.
    #
    class Strategy < PadlockAuth::AbstractStrategy
      include PadlockAuth::Mixins::BuildWith
      include PadlockAuth::Mixins::HideAttribute

      # The configuration builder for `PadlockAuth::Token::Strategy`.
      class Builder < PadlockAuth::Utils::AbstractBuilder; end

      # @!method build
      # @!scope class
      #
      # Builds the stratey instance.
      #
      # @yield block to configure the strategy
      #
      # @return [PadlockAuth::Token::Strategy] the strategy instance
      #
      # @example
      #   PadlockAuth::Token::Strategy.build do
      #     secret_key "my_secret_key"
      #   end
      #
      # @see PadlockAuth::Config::Builder#secure_with
      build_with Builder

      extend PadlockAuth::Config::Option

      # @!attribute [r] secret_key
      #
      # The secret key used to build and authenticate access tokens.
      #
      # @return [String] the secret key
      option :secret_key

      hide_attribute :secret_key

      # Builds an access token from a raw token.
      #
      # @param raw_token [String] The raw token from the request
      #
      # @return [PadlockAuth::Token::AccessToken] The access token
      #
      def build_access_token(raw_token)
        PadlockAuth::Token::AccessToken.new(raw_token, secret_key)
      end

      # Builds an access token from username and password credentials.
      #
      # Only the password is required for this strategy, so the username is ignored.
      #
      # @param _username [String] The (ignored) username
      #
      # @param password [String] The password
      #
      # @return [PadlockAuth::Token::AccessToken] The access token
      #
      def build_access_token_from_credentials(_username, password)
        PadlockAuth::Token::AccessToken.new(password, secret_key)
      end

      # @api private
      #
      # Called by the builder to validate the configuration.
      #
      # @raise [ArgumentError] If the secret key is missing
      #
      def validate!
        raise ArgumentError, "secret_key is required" unless secret_key.present?
      end
    end
  end
end
