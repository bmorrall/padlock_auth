RSpec.describe PadlockAuth do
  it "has a version number" do
    expect(PadlockAuth::VERSION).not_to be nil
  end

  before :each do
    clear_padlock_auth_config!
  end

  describe ".config" do
    it "raises an error if a strategy has not been configured" do
      expect { PadlockAuth.config }.to raise_error(ArgumentError, "strategy has not been configured via secure_with")
    end
  end

  describe ".configure" do
    it "can be configured with a token strategy" do
      PadlockAuth.configure do
        secure_with :token do
          secret_key "my$ecretK3y"
        end
      end

      expect(PadlockAuth.config.strategy).to be_instance_of(PadlockAuth::Token::Strategy)
      expect(PadlockAuth.config.strategy.secret_key).to eq("my$ecretK3y")
    end

    it "can be configured with a token (String) strategy" do
      PadlockAuth.configure do
        secure_with "token" do
          secret_key "my$ecretK3y"
        end
      end

      expect(PadlockAuth.config.strategy).to be_instance_of(PadlockAuth::Token::Strategy)
      expect(PadlockAuth.config.strategy.secret_key).to eq("my$ecretK3y")
    end

    it "can be configured with a PadlockAuth::Token::Strategy" do
      PadlockAuth.configure do
        secure_with PadlockAuth::Token::Strategy do
          secret_key "my$ecretK3y"
        end
      end

      expect(PadlockAuth.config.strategy).to be_instance_of(PadlockAuth::Token::Strategy)
      expect(PadlockAuth.config.strategy.secret_key).to eq("my$ecretK3y")
    end

    it "can be configured with a PadlockAuth::Token::Strategy instance" do
      PadlockAuth.configure do
        strategy = PadlockAuth::Token::Strategy.build do
          secret_key "my$ecretK3y"
        end
        secure_with strategy
      end

      expect(PadlockAuth.config.strategy).to be_instance_of(PadlockAuth::Token::Strategy)
      expect(PadlockAuth.config.strategy.secret_key).to eq("my$ecretK3y")
    end
  end

  context "when configured with a strategy" do
    let(:strategy) { instance_double(PadlockAuth::AbstractStrategy) }

    before :each do
      configured_strategy = strategy
      PadlockAuth.configure do
        secure_with configured_strategy
      end
    end

    it "behaves like a strategy" do
      expect(described_class).to be_a_padlock_auth_strategy
    end

    it "delegates build_access_token the configured strategy" do
      raw_token = "ABC123"
      access_token = instance_double(PadlockAuth::AbstractAccessToken)

      expect(strategy).to receive(:build_access_token).with(raw_token).and_return(access_token)

      expect(PadlockAuth.build_access_token(raw_token)).to be access_token
    end

    it "delegates build_access_token_from_credentials the configured strategy" do
      username = "joebloggs"
      password = "s3cret"
      access_token = instance_double(PadlockAuth::AbstractAccessToken)

      expect(strategy).to receive(:build_access_token_from_credentials).with(username, password).and_return(access_token)

      expect(PadlockAuth.build_access_token_from_credentials(username, password)).to be access_token
    end

    it "delegates build_invalid_token_response the configured strategy" do
      access_token = instance_double(PadlockAuth::AbstractAccessToken)
      invalid_token_response = instance_double(PadlockAuth::Http::InvalidTokenResponse)

      expect(strategy).to receive(:build_invalid_token_response).with(access_token).and_return(invalid_token_response)

      expect(PadlockAuth.build_invalid_token_response(access_token)).to be invalid_token_response
    end

    it "delegates build_forbidden_token_response the configured strategy" do
      access_token = instance_double(PadlockAuth::AbstractAccessToken)
      scopes = %w[read write]
      forbidden_token_response = instance_double(PadlockAuth::Http::ForbiddenTokenResponse)

      expect(strategy).to receive(:build_forbidden_token_response).with(access_token, scopes).and_return(forbidden_token_response)

      expect(PadlockAuth.build_forbidden_token_response(access_token, scopes)).to be forbidden_token_response
    end
  end
end
