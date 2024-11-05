RSpec.describe PadlockAuth::AbstractAccessToken do
  it { is_expected.to be_a_padlock_auth_access_token }

  describe "#acceptable?" do
    it "returns true if record is accessible and includes scopes" do
      allow(subject).to receive(:accessible?).and_return(true)
      allow(subject).to receive(:includes_scope?).with(%w[read write]).and_return(true)

      expect(subject.acceptable?(%w[read write])).to eq(true)
    end

    it "returns false if record is not accessible" do
      allow(subject).to receive(:accessible?).and_return(false)

      expect(subject.acceptable?(%w[read write])).to eq(false)
    end

    it "returns false if record does not include scopes" do
      allow(subject).to receive(:accessible?).and_return(true)
      allow(subject).to receive(:includes_scope?).with(%w[read write]).and_return(false)

      expect(subject.acceptable?(%w[read write])).to eq(false)
    end
  end

  describe "#accessible?" do
    it "warns and returns false" do
      expect(Kernel).to receive(:warn).with("[PADLOCK_AUTH] #accessible? not implemented for PadlockAuth::AbstractAccessToken")

      expect(subject.accessible?).to eq(false)
    end
  end

  describe "#invalid_token_reason" do
    it "defaults to :unknown" do
      expect(subject.invalid_token_reason).to eq(:unknown)
    end
  end

  describe "#includes_scope?" do
    it "warns and returns false" do
      expect(Kernel).to receive(:warn).with("[PADLOCK_AUTH] #includes_scope? not implemented for PadlockAuth::AbstractAccessToken")

      expect(subject.includes_scope?(%w[read write])).to eq(false)
    end
  end

  describe "#forbidden_token_reason" do
    it "defaults to :unknown" do
      expect(subject.forbidden_token_reason).to eq(:unknown)
    end
  end
end
