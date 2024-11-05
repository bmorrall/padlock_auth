# frozen_string_literal: true

module PadlockAuth
  # Errors for PadlockAuth.
  module Errors
    # A generic error for PadlockAuth.
    class PadlockAuthError < StandardError; end

    # An error with a HTTP response.
    class ResponseError < PadlockAuthError
      attr_reader :response

      # Initialize a new response error.
      #
      # @param response [PadlockAuth::Http::ErrorResponse] The response
      def initialize(response)
        @response = response
      end
    end

    # The token is invalid.
    class InvalidToken < ResponseError; end

    # The token has expired.
    class TokenExpired < InvalidToken; end

    # The token has been revoked.
    class TokenRevoked < InvalidToken; end

    # The token is invalid for an unknown reason.
    class TokenUnknown < InvalidToken; end

    # The token is forbidden for the requested resource.
    class TokenForbidden < InvalidToken; end
  end
end
