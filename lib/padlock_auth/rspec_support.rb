# This module provides matchers for testing PadlockAuth access_token and strategy
# classes.
#
# In your implementations, use these shared examples to ensure that your classes
# are compliant with the PadlockAuth API.
#
# @example
#   require "padlock_auth/rspec_support"
#
#   RSpec.describe MyAccessToken do
#     it { is_expected.to be_a_padlock_auth_access_token }
#   end
#
# @example
#   require "padlock_auth/rspec_support"
#
#   RSpec.describe MyStrategy do
#     it { is_expected.to be_a_padlock_auth_strategy }
#   end
module PadlockAuth::Matchers
  # Asserts that the subject matches the expected interface for a PadlockAuth access token.
  #
  # @return [RSpec::Matchers::BuiltIn::BaseMatcher]
  #
  def be_a_padlock_auth_access_token
    respond_to(:acceptable?).with(1).arguments
      .and(respond_to(:accessible?).with(0).arguments)
      .and(respond_to(:includes_scope?).with(1).arguments)
      .and(respond_to(:invalid_token_reason).with(0).arguments)
      .and(respond_to(:forbidden_token_reason).with(0).arguments)
  end

  # Asserts that the subject matches the expected interface for a PadlockAuth strategy.
  #
  # @return [RSpec::Matchers::BuiltIn::BaseMatcher]
  #
  def be_a_padlock_auth_strategy
    respond_to(:build_access_token).with(1).arguments
      .and(respond_to(:build_invalid_token_response).with(1).arguments)
      .and(respond_to(:build_forbidden_token_response).with(2).arguments)
  end
end

RSpec.configure do |config|
  config.include(PadlockAuth::Matchers)
end
