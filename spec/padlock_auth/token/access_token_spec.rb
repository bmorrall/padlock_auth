RSpec.describe PadlockAuth::Token::AccessToken do
  subject(:access_token) { described_class.new(bearer_token, secret_key) }

  let(:bearer_token) { "ABC123" }
  let(:secret_key) { "DEF456" }

  it { is_expected.to be_a_padlock_auth_access_token }

  describe "#accessible?" do
    context "with a bearer token matching the secret key" do
      let(:bearer_token) { "ABC123" }
      let(:secret_key) { "ABC123" }

      it "uses SecureCompare to compare the provided token with the secret key" do
        expect(ActiveSupport::SecurityUtils).to receive(:secure_compare).with(bearer_token, secret_key).and_call_original

        expect(access_token.accessible?).to eq(true)
      end
    end

    context "with a bearer token not matching the secret key" do
      let(:bearer_token) { "ABC123" }
      let(:secret_key) { "DEF456" }

      it "uses SecureCompare to compare the provided token with the secret key" do
        expect(ActiveSupport::SecurityUtils).to receive(:secure_compare).with(bearer_token, secret_key).and_call_original

        expect(access_token.accessible?).to eq(false)
      end
    end
  end

  describe "#includes_scope?" do
    it "allows requests with no required scopes" do
      expect(access_token.includes_scope?([])).to eq(true)
    end

    it "does not allow requests with required scopes" do
      expect do
        expect(access_token.includes_scope?(%w[read write])).to eq(false)
      end.to output("[PADLOCK_AUTH] PadlockAuth::Token::AccessToken does not permit any required scopes\n").to_stderr
    end
  end

  describe "#invalid_token_reason" do
    it "defaults to :unknown" do
      expect(access_token.invalid_token_reason).to eq(:unknown)
    end
  end

  describe "#forbidden_token_reason" do
    it "defaults to :unknown" do
      expect(access_token.forbidden_token_reason).to eq(:unknown)
    end
  end

  describe "#to_json" do
    it "does not expose the bearer token or secret key" do
      expect(access_token.to_json).to eq("{}")
    end
  end

  describe "#inspect" do
    it "does not expose the bearer token" do
      expect(access_token.inspect).not_to include(bearer_token)
    end

    it "does not expose the secret key" do
      expect(access_token.inspect).not_to include(secret_key)
    end
  end
end
