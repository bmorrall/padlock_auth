module PadlockAuth
  module Rails
    ##
    # Helpers for Rails controllers.
    #
    # Provides `padlock_authorize!` method to controllers.
    module Helpers
      protected

      # @!visibility public
      #
      # Authorize the request with the given scopes.
      #
      # If the request is not authorized, an error response will be rendered
      # or an exception will be raised, depending on the configuration.
      #
      # @param scopes [Array<String>] Scopes required for the request, defaults to the default scopes.
      #
      def padlock_authorize!(...)
        padlock_render_error unless padlock_authorized?(...)
      end

      def padlock_authorized?(*scopes)
        @_padlock_auth_scopes = scopes.presence || PadlockAuth.config.default_scopes

        valid_padlock_auth_token?
      end

      # Default render options for unauthorized requests.
      #
      # As the OAuth 2.0 specification does not explicitly define the error response
      # for an invalid request to a protected resource, this method replicates  the
      # error response for an invalid request access token request.
      #
      # @example
      #   {
      #     error: "invalid_grant",
      #     error_description: "The access token is invalid."
      #   }
      #
      # @see https://datatracker.ietf.org/doc/html/rfc6749#section-7.2
      #
      # @see https://datatracker.ietf.org/doc/html/rfc6749#section-5.2
      #
      # @param error [PadlockAuth::Http::InvalidTokenResponse] Invalid grant response.
      #
      # @return [Hash] Render options, passed to `render`
      #
      def padlock_auth_unauthorized_render_options(error:, **)
        {json: error.body, status: error.status}
      end

      # Default render options for forbidden requests.
      #
      # As the OAuth 2.0 specification does not explicitly define the error response
      # for an invalid request to a protected resource, this method replicates  the
      # error response for an invalid request access token request.
      #
      # @example
      #   {
      #     error: "invalid_scope",
      #     error_description: 'Access to this resource requires scope "foo bar baz".'
      #   }
      #
      # @see https://datatracker.ietf.org/doc/html/rfc6749#section-7.2
      #
      # @see https://datatracker.ietf.org/doc/html/rfc6749#section-5.2
      #
      # @param error [PadlockAuth::Http::ForbiddenTokenResponse] Invalid scope response
      #
      # @return [Hash] Render options, passed to `render`
      #
      def padlock_auth_forbidden_render_options(error:, **)
        {json: error.body, status: error.status}
      end

      # @!visibility public
      #
      # Retrieve the access token from the request.
      #
      # Does not check if the token is valid or matches the required scopes.
      #
      # @return [PadlockAuth::AbstractToken, nil] Access token
      #
      def padlock_auth_token
        @padlock_auth_token ||= TokenFactory.authenticate(request)
      end

      private

      def valid_padlock_auth_token?
        padlock_auth_token&.acceptable?(@_padlock_auth_scopes)
      end

      def padlock_render_error
        error = padlock_auth_error
        error.raise_exception! if PadlockAuth.config.raise_on_errors?

        headers.merge!(error.headers.reject { |k| k == "Content-Type" })
        padlock_render_error_with(error)
      end

      def padlock_render_error_with(error)
        options = padlock_auth_render_options(error) || {}
        status = padlock_auth_status_for_error(
          error, options.delete(:respond_not_found_when_forbidden)
        )
        if options.blank? || !respond_to?(:render)
          head status
        else
          options[:status] = status
          options[:layout] = false if options[:layout].nil?
          render options
        end
      end

      def padlock_auth_error
        if padlock_auth_invalid_token_response?
          PadlockAuth.build_invalid_token_response(padlock_auth_token)
        else
          PadlockAuth.build_forbidden_token_response(padlock_auth_token, @_padlock_auth_scopes)
        end
      end

      def padlock_auth_render_options(error)
        if padlock_auth_invalid_token_response?
          padlock_auth_unauthorized_render_options(error: error)
        else
          padlock_auth_forbidden_render_options(error: error)
        end
      end

      def padlock_auth_status_for_error(error, respond_not_found_when_forbidden)
        if respond_not_found_when_forbidden && error.status == :forbidden
          :not_found
        else
          error.status
        end
      end

      def padlock_auth_invalid_token_response?
        !padlock_auth_token || !padlock_auth_token.accessible?
      end
    end
  end
end
