module PadlockAuth::ConfigurationHelpers
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
