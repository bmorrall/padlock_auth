RSpec.describe PadlockAuth::Token::Strategy do
  subject(:strategy) { described_class.build { secret_key "my$ecretK3y" } }

  it { is_expected.to be_a(described_class) }

  it { is_expected.to be_a_padlock_auth_strategy }

  describe ".build" do
    it "generates a new instance of the strategy" do
      strategy = described_class.build { secret_key "ABC123" }

      expect(strategy).to be_a(described_class)
      expect(strategy.secret_key).to eq("ABC123")
    end

    it "raises an error if no secret key is provided" do
      expect {
        described_class.build {}
      }.to raise_error(ArgumentError, "secret_key is required")
    end

    it "raises an error if a blank secret key is provided" do
      expect {
        described_class.build { secret_key "" }
      }.to raise_error(ArgumentError, "secret_key is required")
    end

    it "raises an error if no block is given" do
      expect {
        described_class.build
      }.to raise_error(ArgumentError, "secret_key is required")
    end
  end

  describe "#build_access_token" do
    it "returns a PadlockAuth::Token::AccessToken with the configured secret key" do
      raw_token = "ABC123"

      access_token = instance_double(PadlockAuth::Token::AccessToken)
      expect(PadlockAuth::Token::AccessToken).to receive(:new).with(raw_token, strategy.secret_key).and_return(access_token)

      expect(strategy.build_access_token(raw_token)).to be access_token
    end
  end

  describe "#build_access_token_from_credentials" do
    it "returns a PadlockAuth::Token::AccessToken from the password with the configured secret key" do
      password = "ABC123"

      access_token = instance_double(PadlockAuth::Token::AccessToken)
      expect(PadlockAuth::Token::AccessToken).to receive(:new).with(password, strategy.secret_key).and_return(access_token)

      expect(strategy.build_access_token_from_credentials("user", password)).to be access_token
    end
  end

  describe "#build_invalid_token_response" do
    it "returns a PadlockAuth::Http::InvalidTokenResponse" do
      access_token = instance_double(PadlockAuth::Token::AccessToken, invalid_token_reason: :revoked)

      invalid_token_response = strategy.build_invalid_token_response(access_token)
      expect(invalid_token_response).to be_a(PadlockAuth::Http::InvalidTokenResponse)
      expect(invalid_token_response.reason).to eq(:revoked)
    end
  end

  describe "#build_forbidden_token_response" do
    it "returns a PadlockAuth::Http::ForbiddenTokenResponse" do
      access_token = instance_double(PadlockAuth::Token::AccessToken, forbidden_token_reason: :missing_scope)
      scopes = %w[read write]

      forbidden_token_response = strategy.build_forbidden_token_response(access_token, scopes)
      expect(forbidden_token_response).to be_a(PadlockAuth::Http::ForbiddenTokenResponse)
      expect(forbidden_token_response.reason).to eq(:missing_scope)
    end
  end

  describe "#to_json" do
    it "does not expose the secret key" do
      expect(strategy.to_json).to eq("{}")
    end
  end

  describe "#inspect" do
    it "does not expose the secret key" do
      expect(strategy.inspect).not_to include("my$ecretK3y")
    end
  end
end
