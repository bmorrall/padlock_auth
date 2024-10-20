module PadlockAuth::ConfigurationHelpers
  # Convenience method to configure PadlockAuth with the token strategy
  def secure_with_token_strategy!(secret_key, **config_options, &)
    PadlockAuth.configure do
      secure_with :token do
        secret_key secret_key
      end

      config_options.each do |key, value|
        send(key, value)
      end
    end
  end

  def clear_padlock_auth_config!
    PadlockAuth.remove_instance_variable(:@config) if PadlockAuth.instance_variable_defined?(:@config)
  end
end

RSpec.configure do |config|
  config.before(:all) do
    clear_padlock_auth_config!
  end

  config.include PadlockAuth::ConfigurationHelpers
end
