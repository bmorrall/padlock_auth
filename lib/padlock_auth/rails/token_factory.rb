# frozen_string_literal: true

module PadlockAuth
  module Rails
    ##
    # Responsible for extracting access tokens from requests,
    # and delgating the creation of access tokens to the configured strategy.
    class TokenFactory
      class << self
        # Retreives the access token from the request using the configured methods.
        def from_request(request, *methods)
          methods.inject(nil) do |_, method|
            method = self.method(method) if method.is_a?(Symbol)
            credentials = method.call(request)
            break credentials if credentials.present?
          end
        end

        # Retreives the access token from the request, and builds an access token object.
        def authenticate(request)
          if (token = from_request(request, *PadlockAuth.config.access_token_methods))
            if token.is_a?(Array)
              PadlockAuth.build_access_token_from_credentials(*token)
            else
              PadlockAuth.build_access_token(token)
            end
          end
        end

        # Extracts the access token from the `access_token` parameter.
        #
        # @param request [ActionDispatch::Request] request
        #
        # @return [String, nil] Access token
        #
        def from_access_token_param(request)
          request.parameters[:access_token]
        end

        # Extracts the access token from the `bearer_token` parameter.
        #
        # @param request [ActionDispatch::Request] request
        #
        # @return [String, nil] Access token
        #
        def from_bearer_param(request)
          request.parameters[:bearer_token]
        end

        # Extracts a Bearer access token from the `Authorization` header.
        #
        # @param request [ActionDispatch::Request] request
        #
        # @return [String, nil] Access token
        #
        def from_bearer_authorization(request)
          pattern = /^Bearer /i
          header = request.authorization
          token_from_header(header, pattern) if match?(header, pattern)
        end

        # Extracts Basic Auth credentials from the `Authorization` header.
        #
        # @param request [ActionDispatch::Request] request
        #
        # @return [Array, nil] Username and password
        #
        def from_basic_authorization(request)
          pattern = /^Basic /i
          header = request.authorization
          token_from_basic_header(header, pattern) if match?(header, pattern)
        end

        private

        def token_from_basic_header(header, pattern)
          encoded_header = token_from_header(header, pattern)
          decode_basic_credentials_token(encoded_header)
        end

        def decode_basic_credentials_token(encoded_header)
          Base64.decode64(encoded_header).split(":", 2)
        end

        def token_from_header(header, pattern)
          header.gsub(pattern, "")
        end

        def match?(header, pattern)
          header&.match(pattern)
        end
      end
    end
  end
end
