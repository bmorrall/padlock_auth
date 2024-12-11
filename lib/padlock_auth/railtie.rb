module PadlockAuth
  ##
  # Railtie for PadlockAuth.
  #
  # Provides `padlock_authorize!` and `padlock_auth_token` methods to Rails controllers.
  #
  # Also adds PadlockAuth's locales to I18n.load_path.
  #
  class Railtie < ::Rails::Railtie
    initializer "padlock_auth.helpers" do
      ActiveSupport.on_load(:action_controller) do
        include PadlockAuth::Rails::Helpers
      end
      ActiveSupport.on_load(:action_cable) do
        ActionCable::Connection::Base.include PadlockAuth::Rails::Helpers
        ActionCable::Channel::Base.include PadlockAuth::Rails::ActionCableChannelHelpers
      end
    end

    initializer "padlock_auth.i18n" do
      Dir.glob(File.join(File.dirname(__FILE__), "..", "..", "config", "locales", "*.yml")).each do |file|
        I18n.load_path << File.expand_path(file)
      end
    end
  end
end
