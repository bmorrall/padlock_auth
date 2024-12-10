require "rails"

require "padlock_auth/version"
require "padlock_auth/railtie"
require "padlock_auth/errors"

# PadlockAuth allows you to secure your Rails application using access tokens
# provided by an external provider.
#
module PadlockAuth
  # Abstract classes recommended for extension
  autoload :AbstractAccessToken, "padlock_auth/abstract_access_token"
  autoload :AbstractStrategy, "padlock_auth/abstract_strategy"

  # Configuration classes
  autoload :Config, "padlock_auth/config"

  # Token stategy classes
  module Token
    autoload :AccessToken, "padlock_auth/token/access_token"
    autoload :Strategy, "padlock_auth/token/strategy"
  end

  # Mixins for extending classes
  module Mixins
    autoload :BuildWith, "padlock_auth/mixins/build_with"
    autoload :HideAttribute, "padlock_auth/mixins/hide_attribute"
  end

  module Utils
    autoload :AbstractBuilder, "padlock_auth/utils/abstract_builder"
  end

  # HTTP response classes
  module Http
    autoload :ErrorResponse, "padlock_auth/http/error_response"
    autoload :ForbiddenTokenResponse, "padlock_auth/http/forbidden_token_response"
    autoload :InvalidTokenResponse, "padlock_auth/http/invalid_token_response"
  end

  # Rails-specific classes
  module Rails
    autoload :ActionCableChannelHelpers, "padlock_auth/rails/action_cable_channel_helpers"
    autoload :Helpers, "padlock_auth/rails/helpers"
    autoload :TokenFactory, "padlock_auth/rails/token_factory"
  end

  class << self
    # Configure PadlockAuth.
    #
    # @yield [PadlockAuth::Config] configuration block
    #
    def configure(&)
      @config = Config.build(&)
    end

    # @return [PadlockAuth::Config] configuration instance
    #
    def configuration
      @config || configure
    end

    alias_method :config, :configuration

    ### Strategy Delegation ###

    delegate :build_access_token,
      :build_access_token_from_credentials,
      :build_invalid_token_response,
      :build_forbidden_token_response,
      to: :strategy

    delegate :strategy, to: :config
    private :strategy
  end
end
