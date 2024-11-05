# frozen_string_literal: true

module PadlockAuth
  module Http
    ##
    # A response for a forbidden token.
    #
    # A forbidden token response is returned when a token is valid,
    # but does not have the required scopes.
    #
    class ForbiddenTokenResponse < ErrorResponse
      attr_reader :reason

      ##
      # Create a new forbidden token response from an access token.
      #
      # @param access_token [PadlockAuth::AbstractAccessToken] Access token
      #
      # @param scopes [Array<String>] Required scopes
      #
      # @param attributes [Hash] Additional attributes
      #
      def self.from_access_token(access_token, scopes, attributes = {})
        new(attributes.merge(reason: access_token&.forbidden_token_reason, scopes: scopes))
      end

      # Create a new forbidden token response.
      #
      # @param attributes [Hash] Attributes
      #
      def initialize(attributes = {})
        super(attributes.merge(name: :invalid_scope, status: :forbidden))
        @reason = attributes[:reason] || :unknown
        @scopes = attributes[:scopes]
      end

      # @!attribute [r] description
      # @return [String] A translated description of the error
      #
      def description
        @description ||=
          I18n.translate(
            @reason,
            scope: %i[padlock_auth errors messages forbidden_token],
            oauth_scopes: @scopes.map(&:to_s).join(" "),
            default: :unknown
          )
      end

      # @return [Hash] HTTP headers
      #
      def headers
        headers = super
        headers.delete "WWW-Authenticate" # Authentication was successful, so no need to display auth error info
        headers
      end

      protected

      # @return [Class<PadlockAuth::Errors::TokenForbidden>] Exception class
      #
      def exception_class
        PadlockAuth::Errors::TokenForbidden
      end
    end
  end
end
