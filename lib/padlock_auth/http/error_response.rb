# frozen_string_literal: true

module PadlockAuth
  module Http
    ##
    # A generic error response for PadlockAuth.
    #
    # This class is intended to be extended by specific error responses.
    #
    class ErrorResponse
      # @param attributes [Hash] error attributes
      #
      def initialize(attributes = {})
        @name = attributes[:name]
        @status = attributes[:status] || :bad_request
      end

      # @return [Symbol] The error name
      attr_reader :name

      # @return [Symbol] The HTTP status code
      attr_reader :status

      # @!attribute [r] description
      # @return [String] A human-readable description of the error
      def description
        I18n.translate(
          name,
          scope: %i[padlock_auth errors messages],
          default: :server_error
        )
      end

      # @return [Hash] JSON response body
      #
      def body
        {
          error: name,
          error_description: description
        }.reject { |_, v| v.blank? }
      end

      # @return [Hash] HTTP headers
      #
      def headers
        {
          "Cache-Control" => "no-store, no-cache",
          "Content-Type" => "application/json; charset=utf-8",
          "WWW-Authenticate" => authenticate_info
        }
      end

      # Raise an exception based on the error response.
      #
      # @raise [PadlockAuth::Errors::ResponseError] with the error response
      def raise_exception!
        raise exception_class.new(self), description
      end

      protected

      # @return [Class<ResponseError>] Exception class to raise
      #
      def exception_class
        raise NotImplementedError, "error response must define #exception_class"
      end

      private

      def authenticate_info
        %(Bearer realm="#{PadlockAuth.config.realm}", error="#{name}", error_description="#{description}")
      end
    end
  end
end
