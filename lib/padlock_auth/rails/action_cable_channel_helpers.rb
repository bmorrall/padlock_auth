module PadlockAuth
  module Rails
    module ActionCableChannelHelpers
      module TokenFactory
        module_function

        # Retreives the access token from the request using the configured methods.
        def from_params(params, *methods)
          methods.inject(nil) do |_, method|
            method = self.method(method) if method.is_a?(Symbol)
            credentials = method.call(params)
            break credentials if credentials.present?
          end
        end

        # Retreives the access token from the params, and builds an access token object.
        def authenticate(params)
          if (token = from_params(params, *PadlockAuth.config.action_cable_methods))
            PadlockAuth.build_access_token(token)
          end
        end

        # Extracts the access token from the `access_token` parameter.
        #
        # @param params [ActionDispatch::Request] params
        #
        # @return [String, nil] Access token
        #
        def from_access_token_param(params)
          params[:access_token]
        end

        # Extracts the access token from the `bearer_token` parameter.
        #
        # @param params [ActiveSupport::HashWithIndifferentAccess] params
        #
        # @return [String, nil] Access token
        #
        def from_bearer_param(params)
          params[:bearer_token]
        end
      end

      # @!visibility public
      #
      # Authorize the request with the given scopes.
      #
      # If the request is not authorized, an error response will be rendered
      # or an exception will be raised, depending on the configuration.
      #
      # @param scopes [Array<String>] Scopes required for the request, defaults to the default scopes.
      # @return [Boolean] Whether the request is authorized.
      #
      def padlock_authorized?(*scopes)
        padlock_auth_token&.acceptable?(scopes.presence || PadlockAuth.config.default_scopes)
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
        @padlock_auth_token ||= TokenFactory.authenticate(params)
      end
    end
  end
end
