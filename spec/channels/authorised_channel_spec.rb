require "rails_helper"

# This is the minimal ActionCable connection stub to make the test pass
class TestConnection
  attr_reader :identifiers, :logger

  def initialize(identifiers_hash = {})
    @identifiers = identifiers_hash.keys
    @logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(StringIO.new))

    # This is an equivalent of providing `identified_by :identifier_key` in ActionCable::Connection::Base subclass
    identifiers_hash.each do |identifier, value|
      define_singleton_method(identifier) do
        value
      end
    end
  end
end

RSpec.describe AuthorizedChannel, type: :channel do
  include ActionCable::TestHelper

  context "when authorized with a connection" do
    let(:strategy) { instance_double(PadlockAuth::AbstractStrategy) }

    before :each do
      # initialize connection
      stub_connection

      # configure strategy
      configured_strategy = strategy
      PadlockAuth.configure do
        secure_with configured_strategy
      end
    end

    it "subscribes with a valid token provided via an access_token param" do
      expect(strategy).to receive(:build_access_token)
        .with("valid_token")
        .and_return(instance_double(PadlockAuth::AbstractAccessToken, acceptable?: true))

      subscribe access_token: "valid_token"
      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_from("authorized_stream")
    end

    it "subscribes with a valid token provided via a bearer_token param" do
      expect(strategy).to receive(:build_access_token)
        .with("valid_token")
        .and_return(instance_double(PadlockAuth::AbstractAccessToken, acceptable?: true))

      subscribe bearer_token: "valid_token"
      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_from("authorized_stream")
    end

    it "does not subscribe with an invalid token" do
      expect(strategy).to receive(:build_access_token)
        .with("invalid_token")
        .and_return(instance_double(PadlockAuth::AbstractAccessToken, acceptable?: false))

      subscribe access_token: "invalid_token"
      expect(subscription).to be_rejected
    end

    it "does not subscribe without a token" do
      expect(strategy).not_to receive(:build_access_token)

      subscribe
      expect(subscription).to be_rejected
    end
  end
end
