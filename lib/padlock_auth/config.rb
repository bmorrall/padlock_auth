require "padlock_auth/config/option"
require "padlock_auth/config/scopes"

module PadlockAuth
  # Configuration for PadlockAuth.
  #
  # @example
  #   PadlockAuth.configure do |config|
  #     config.secure_with :token do
  #       secret_key "my_secret_key"
  #     end
  #
  #     config.default_scopes :read, :write
  #     config.access_token_methods :from_bearer_authorization, :from_access_token_param
  #     config.raise_on_errors!
  #   end
  #
  class Config
    include PadlockAuth::Mixins::BuildWith

    # The configuration builder for `PadlockAuth::Config`.
    #
    # @see PadlockAuth::Utils::AbstractBuilder
    #
    class Builder < PadlockAuth::Utils::AbstractBuilder
      # Configure the strategy to use for authentication.
      #
      # Strategies are responsible for building access tokens and authenticating them.
      # PadlockAuth comes with a default strategy, `PadlockAuth::Token::Strategy`,
      # which uses a shared secret key to build and authenticate access tokens.
      #
      # A strategy can be provided as:
      # - an instance of `PadlockAuth::AbstractStrategy`, or one matching its interface,
      # - a class that responds to `.build` and returns an instance of `PadlockAuth::AbstractStrategy`, or
      # - a string or symbol representing a built-in strategy (e.g. `:token`)
      #
      # The string or symbol strategy will be resolved to a class in the `PadlockAuth` namespace
      # by appending `::Strategy` to the string and looking up the constant in the `PadlockAuth`
      # namespace. For example, `:token` will resolve to `PadlockAuth::Token::Strategy`.
      #
      # You can define your own strategy by subclassing `PadlockAuth::AbstractStrategy`,
      # and passing an instance of your strategy to `secure_with`, or by using the naming convention
      # and passing a string or symbol.
      #
      # @param strategy [PadlockAuth::AbstractStrategy, Class, String, Symbol] The strategy to use for authentication
      #
      # @yield A block to configure the strategy (yielded by the strategy's `build` method)
      #
      # @return [PadlockAuth::AbstractStrategy] The strategy instance
      def secure_with(strategy, &)
        strategy = case strategy
        when String, Symbol
          strategy_klass = "PadlockAuth::#{strategy.to_s.camelize}::Strategy".safe_constantize
          raise ArgumentError, "unknown strategy: #{strategy}" unless strategy_klass
          strategy_klass.build(&)
        when Class
          strategy.build(&)
        else
          strategy
        end
        config.instance_variable_set(:@strategy, strategy)
      end

      # Define default access token scopes for your endpoint.
      #
      # Scopes are used to limit access to certain parts of your API. When a token
      # is created, it is assigned a set of scopes that define what it can access.
      #
      # Calls to `padlock_authorize!` will check that the token has the required scopes,
      # if no scopes are provided, the default scopes will be used.
      #
      # @param scopes [Array] Default set of access (PadlockAuth::Config::Scopes.new)
      # token scopes
      #
      def default_scopes(*scopes)
        config.instance_variable_set(:@default_scopes, PadlockAuth::Config::Scopes.from_array(*scopes))
      end

      # Change the way access token is authenticated from the request object.
      #
      # By default it retrieves a Bearer token from the `HTTP_AUTHORIZATION` header, then
      # falls back to the `:access_token` or `:bearer_token` params from the
      # `params` object.
      #
      # Available methods:
      # - `:from_bearer_authorization` - Extracts a Bearer token from the `HTTP_AUTHORIZATION` header
      # - `:from_access_token_param` - Extracts the token from the `:access_token` param
      # - `:from_bearer_param` - Extracts the token from the `:bearer_token` param
      # - `:from_basic_authorization` - Extracts Basic Auth credentials from the `HTTP_AUTHORIZATION` header
      #
      # @param methods [Array<Symbol>] Define access token methods, in order of preference
      #
      def access_token_methods(*methods)
        config.instance_variable_set(:@access_token_methods, methods.flatten.compact)
      end

      def action_cable_methods(*methods)
        config.instance_variable_set(:@action_cable_methods, methods.flatten.compact)
      end

      # Calls to `padlock_authorize!` will raise an exception when authentication fails.
      #
      def raise_on_errors!
        handle_auth_errors(:raise)
      end

      # Calls to `padlock_authorize!` will render an error response when authentication fails.
      #
      # This is the default behavior.
      #
      def render_on_errors!
        handle_auth_errors(:render)
      end
    end

    # @!method build(&)
    # @!scope class
    #
    # Builds the configuration instance using the builder.
    #
    # @yield block to configure the configuration
    #
    # @return [PadlockAuth::Config] the configuration instance
    #
    # @see PadlockAuth::Config::Builder
    build_with Builder

    extend PadlockAuth::Config::Option

    # @!attribute [r] realm
    #
    # The strategy to use for authentication.
    #
    # @return [PadlockAuth::AbstractStrategy] The authentication strategy
    #
    attr_reader :strategy

    # @!attribute [r] realm
    #
    # WWW-Authenticate Realm (default "PadlockAuth").
    #
    # @return [String] The Authentication realm
    #
    option :realm, default: "PadlockAuth"

    # @!attribute [r] default_scopes
    #
    # Default required scopes, used whenever `padlock_authorize!` is called without arguments.
    #
    # Empty by default.
    #
    # @return [PadlockAuth::Config::Scopes] Default required scopes
    #
    def default_scopes
      @default_scopes ||= PadlockAuth::Config::Scopes.new
    end

    # @!attribute [r] access_token_methods
    #
    # Methods to extract the access token from the request.
    #
    # @see PadlockAuth::Rails::TokenExtractor for available methods
    #
    # @return [Array<Symbol>] Methods to extract the access token
    #
    def access_token_methods
      @access_token_methods ||= %i[
        from_bearer_authorization
        from_access_token_param
        from_bearer_param
      ]
    end

    def action_cable_methods
      @action_cable_methods ||= %i[
        from_access_token_param
        from_bearer_param
      ]
    end

    # @!attribute [r] handle_auth_errors
    #
    # How to handle authentication errors.
    #
    # - `:raise` - Raise an exception when authentication fails
    # - `:render` - Render an error response when authentication fails
    #
    # @return [Symbol] The error handling method
    #
    option :handle_auth_errors, default: :render

    # @return [Boolean] Whether to render an error response when authentication fails
    #
    def render_on_errors?
      handle_auth_errors == :render
    end

    # @return [Boolean] Whether to raise an exception when authentication fails
    #
    def raise_on_errors?
      handle_auth_errors == :raise
    end

    # @api private
    #
    # Called by PadlockAuth::Utils::AbstractBuilder#build to validate the configuration.
    #
    # @raise [ArgumentError] If the configuration is invalid
    #
    def validate!
      raise ArgumentError, "strategy has not been configured via secure_with" if strategy.nil?

      raise ArgumentError, "realm is required" if realm.blank?

      unless handle_auth_errors.in? %i[raise render]
        raise ArgumentError, "handle_auth_errors must be :raise, or :render"
      end

      true
    end
  end
end
