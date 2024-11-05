# frozen_string_literal: true

module PadlockAuth
  module Http
    ##
    # A response for an invalid token.
    #
    # An invalid token response is returned when a token is invalid.
    #
    class InvalidTokenResponse < ErrorResponse
      # Reason for the invalid token.
      #
      # Possible reasons are:
      # - :revoked
      # - :expired
      # - :unknown
      #
      # @return [Symbol] The reason for the invalid token
      attr_reader :reason

      # Create a new invalid token response from an access token.
      #
      # @param access_token [PadlockAuth::AbstractAccessToken] Access token
      #
      # @param attributes [Hash] Additional attributes
      #
      def self.from_access_token(access_token, attributes = {})
        new(attributes.merge(reason: access_token&.invalid_token_reason))
      end

      # Create a new invalid token response.
      #
      # @param attributes [Hash] Attributes
      #
      def initialize(attributes = {})
        super(attributes.merge(name: :invalid_grant, status: :unauthorized))
        @reason = attributes[:reason] || :unknown
      end

      # @!attribute [r] description
      # @return [String] A translated description of the error
      #
      def description
        @description ||=
          I18n.translate(
            reason,
            scope: %i[padlock_auth errors messages invalid_token],
            default: :unknown
          )
      end

      protected

      # Return the exception class for the error response.
      #
      # Depending on the reason, a different exception class will be raised.
      #
      # Defaults to `PadlockAuth::Errors::TokenUnknown`.
      #
      # @return [Class<InvalidToken>] Exception class
      #
      def exception_class
        {
          revoked: PadlockAuth::Errors::TokenRevoked,
          expired: PadlockAuth::Errors::TokenExpired
        }.fetch(reason, PadlockAuth::Errors::TokenUnknown)
      end
    end
  end
end
