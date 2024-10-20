module PadlockAuth
  module Token
    ##
    # Access token for simple token authentication.
    #
    # Represents a string token that is compared to a secret key.
    #
    # Does not allow for scopes, so it will always return false for any required
    class AccessToken < PadlockAuth::AbstractAccessToken
      include PadlockAuth::Mixins::HideAttribute

      hide_attribute :token
      hide_attribute :secret_key

      # Initialize the access token with a token and secret key.
      #
      # @param token [String] The token
      #
      # @param secret_key [String] The secret key
      #
      def initialize(token, secret_key)
        @token = token
        @secret_key = secret_key
      end

      # Check if the token matches the secret key.
      #
      # @return [Boolean] true if the token matches the secret key
      #
      def accessible?
        # Compare the tokens in a time-constant manner, to mitigate timing attacks.
        ActiveSupport::SecurityUtils.secure_compare(@token, @secret_key)
      end

      # Check if the token includes the required scopes.
      #
      # Simple tokens do not include scopes, so this method will return false
      # for any required scopes.
      #
      # @return [Boolean] true if the token includes the required scopes
      #
      def includes_scope?(required_scopes)
        required_scopes.none?.tap do |result|
          Kernel.warn "[PADLOCK_AUTH] #{self.class} does not permit any required scopes" unless result
        end
      end

      # The token secret_key does not permit any required scopes, so display a generic message
      #
      def forbidden_token_reason
        :unknown
      end
    end
  end
end
