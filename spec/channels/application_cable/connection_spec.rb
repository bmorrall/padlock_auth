require "rails_helper"

RSpec.describe ApplicationCable::Connection do
  context "when configured with a padlock_auth strategy" do
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

    it "connects with a valid access token provided as an access_token param" do
      valid_access_token = instance_double(PadlockAuth::AbstractAccessToken, acceptable?: true)
      # implementation-specific subject method
      def valid_access_token.subject
        "token_subject"
      end
      expect(strategy).to receive(:build_access_token)
        .with("valid_token")
        .and_return(valid_access_token)

      connect "/cable?access_token=valid_token"

      expect(connection.access_token_subject).to eq "token_subject"
    end

    it "connects with a valid access token provided as a bearer_token param" do
      valid_access_token = instance_double(PadlockAuth::AbstractAccessToken, acceptable?: true)
      # implementation-specific subject method
      def valid_access_token.subject
        "token_subject"
      end
      expect(strategy).to receive(:build_access_token)
        .with("valid_token")
        .and_return(valid_access_token)

      connect "/cable?bearer_token=valid_token"

      expect(connection.access_token_subject).to eq "token_subject"
    end

    it "rejects connections without a valid access token" do
      invalid_access_token = instance_double(PadlockAuth::AbstractAccessToken, acceptable?: false)
      expect(strategy).to receive(:build_access_token)
        .with("invalid")
        .and_return(invalid_access_token)

      expect { connect "/cable?access_token=invalid" }.to have_rejected_connection
    end

    it "rejects connections a provided access token" do
      expect { connect "/cable" }.to have_rejected_connection
    end
  end
end
