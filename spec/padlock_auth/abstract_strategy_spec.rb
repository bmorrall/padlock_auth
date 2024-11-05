RSpec.describe PadlockAuth::AbstractStrategy do
  it { is_expected.to be_a_padlock_auth_strategy }

  describe "#build_access_token" do
    it "returns nil" do
      expect do
        expect(subject.build_access_token("ABC123")).to be_nil
      end.to output("[PADLOCK_AUTH] #build_access_token not implemented for PadlockAuth::AbstractStrategy\n").to_stderr
    end
  end

  describe "#build_access_token_from_credentials" do
    it "returns nil" do
      expect do
        expect(subject.build_access_token_from_credentials("user", "pass")).to be_nil
      end.to output("[PADLOCK_AUTH] #build_access_token_from_credentials not implemented for PadlockAuth::AbstractStrategy\n").to_stderr
    end
  end

  describe "#build_invalid_token_response" do
    it "returns an instance of Http::InvalidTokenResponse" do
      access_token = instance_double(PadlockAuth::AbstractAccessToken, invalid_token_reason: :revoked)

      invalid_token_response = subject.build_invalid_token_response(access_token)
      expect(invalid_token_response).to be_a(PadlockAuth::Http::InvalidTokenResponse)
      expect(invalid_token_response.reason).to eq(:revoked)
    end
  end

  describe "#build_forbidden_token_response" do
    it "returns an instance of Http::ForbiddenTokenResponse" do
      access_token = instance_double(PadlockAuth::AbstractAccessToken, forbidden_token_reason: :missing_scope)
      scopes = %w[read write]

      forbidden_token_response = subject.build_forbidden_token_response(access_token, scopes)
      expect(forbidden_token_response).to be_a(PadlockAuth::Http::ForbiddenTokenResponse)
      expect(forbidden_token_response.reason).to eq(:missing_scope)
    end
  end
end
