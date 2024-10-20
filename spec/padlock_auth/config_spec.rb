RSpec.describe PadlockAuth::Config do
  describe "#strategy" do
    it "can be configured an instance of PadlockAuth::AbstractStrategy" do
      configured_strategy = instance_double(PadlockAuth::AbstractStrategy)
      config = described_class.build do
        secure_with configured_strategy
      end

      expect(config.strategy).to be configured_strategy
    end

    it "can be configured with a token strategy" do
      config = described_class.build do
        secure_with :token do
          secret_key "my$ecretK3y"
        end
      end

      expect(config.strategy).to be_instance_of(PadlockAuth::Token::Strategy)
      expect(config.strategy.secret_key).to eq("my$ecretK3y")
    end

    it "can be configured with a token (String) strategy" do
      config = described_class.build do
        secure_with "token" do
          secret_key "my$ecretK3y"
        end
      end

      expect(config.strategy).to be_instance_of(PadlockAuth::Token::Strategy)
      expect(config.strategy.secret_key).to eq("my$ecretK3y")
    end

    it "can be configured with a PadlockAuth::Token::Strategy class" do
      config = described_class.build do
        secure_with PadlockAuth::Token::Strategy do
          secret_key "my$ecretK3y"
        end
      end

      expect(config.strategy).to be_instance_of(PadlockAuth::Token::Strategy)
      expect(config.strategy.secret_key).to eq("my$ecretK3y")
    end

    it "can be configured an instance of PadlockAuth::Token::Strategy" do
      config = described_class.build do
        strategy = PadlockAuth::Token::Strategy.build do
          secret_key "my$ecretK3y"
        end
        secure_with strategy
      end

      expect(config.strategy).to be_instance_of(PadlockAuth::Token::Strategy)
      expect(config.strategy.secret_key).to eq("my$ecretK3y")
    end

    it "raises an error for an unknown strategy" do
      expect do
        described_class.build do
          secure_with :unknown
        end
      end.to raise_error(ArgumentError, "unknown strategy: unknown")
    end

    it "raises an error if the strategy does not provide a build method" do
      expect do
        described_class.build do
          secure_with String do
            secret_key "my$ecretK3y"
          end
        end
      end.to raise_error(NoMethodError, "undefined method `build' for class String")
    end
  end

  describe "#realm" do
    it "has a default realm" do
      strategy = instance_double(PadlockAuth::AbstractStrategy)
      config = described_class.build do
        secure_with strategy
      end
      expect(config.realm).to eq("PadlockAuth")
    end

    it "can be configured with a custom realm" do
      strategy = instance_double(PadlockAuth::AbstractStrategy)
      config = described_class.build do
        secure_with strategy
        realm "MyRealm"
      end

      expect(config.realm).to eq("MyRealm")
    end

    it "does not allow realm to be nil" do
      expect do
        strategy = instance_double(PadlockAuth::AbstractStrategy)
        described_class.build do
          secure_with strategy
          realm nil
        end
      end.to raise_error(ArgumentError, "realm is required")
    end

    it "does not allow realm to be an empty string" do
      expect do
        strategy = instance_double(PadlockAuth::AbstractStrategy)
        described_class.build do
          secure_with strategy
          realm ""
        end
      end.to raise_error(ArgumentError, "realm is required")
    end
  end

  describe "#default_scopes" do
    it "returns an empty instance of PadlockAuth::Config::Scopes" do
      strategy = instance_double(PadlockAuth::AbstractStrategy)
      config = described_class.build do
        secure_with strategy
      end
      expect(config.default_scopes).to be_a(PadlockAuth::Config::Scopes)
    end

    it "returns an empty collection by default" do
      strategy = instance_double(PadlockAuth::AbstractStrategy)
      config = described_class.build do
        secure_with strategy
      end
      expect(config.default_scopes).to be_empty
    end

    it "can be configured with default scopes" do
      strategy = instance_double(PadlockAuth::AbstractStrategy)
      config = described_class.build do
        secure_with strategy
        default_scopes :read, :write
      end
      expect(config.default_scopes).to contain_exactly("read", "write")
    end

    it "can be configured with an array of symbols" do
      strategy = instance_double(PadlockAuth::AbstractStrategy)
      config = described_class.build do
        secure_with strategy
        default_scopes [:read, :write]
      end
      expect(config.default_scopes).to contain_exactly("read", "write")
    end

    it "can be configured with an array of strings" do
      strategy = instance_double(PadlockAuth::AbstractStrategy)
      config = described_class.build do
        secure_with strategy
        default_scopes ["read", "write"]
      end
      expect(config.default_scopes).to contain_exactly("read", "write")
    end

    it "allows default scopes to be nil" do
      strategy = instance_double(PadlockAuth::AbstractStrategy)
      config = described_class.build do
        secure_with strategy
        default_scopes nil
      end
      expect(config.default_scopes).to be_empty
    end
  end

  describe "#access_token_methods" do
    it "has default access token methods" do
      strategy = instance_double(PadlockAuth::AbstractStrategy)
      config = described_class.build do
        secure_with strategy
      end
      expect(config.access_token_methods).to contain_exactly(
        :from_bearer_authorization,
        :from_access_token_param,
        :from_bearer_param
      )
    end

    it "can be configured with a single access token method" do
      strategy = instance_double(PadlockAuth::AbstractStrategy)
      config = described_class.build do
        secure_with strategy
        access_token_methods :from_bearer_param
      end
      expect(config.access_token_methods).to contain_exactly(:from_bearer_param)
    end

    it "can be configured with custom access token methods" do
      strategy = instance_double(PadlockAuth::AbstractStrategy)
      config = described_class.build do
        secure_with strategy
        access_token_methods :from_custom_method
      end
      expect(config.access_token_methods).to contain_exactly(:from_custom_method)
    end

    it "can be configured with multiple access token methods" do
      strategy = instance_double(PadlockAuth::AbstractStrategy)
      config = described_class.build do
        secure_with strategy
        access_token_methods :from_bearer_param, :from_access_token_param
      end
      expect(config.access_token_methods).to contain_exactly(
        :from_bearer_param,
        :from_access_token_param
      )
    end

    it "allows access token methods to be nil" do
      strategy = instance_double(PadlockAuth::AbstractStrategy)
      config = described_class.build do
        secure_with strategy
        access_token_methods nil
      end
      expect(config.access_token_methods).to be_empty
    end
  end

  describe "#handle_auth_errors" do
    it "has a default error handling strategy" do
      strategy = instance_double(PadlockAuth::AbstractStrategy)
      config = described_class.build do
        secure_with strategy
      end
      expect(config.handle_auth_errors).to eq(:render)
      expect(config.render_on_errors?).to be(true)
      expect(config.raise_on_errors?).to be(false)
    end

    it "can be configured to render on errors" do
      strategy = instance_double(PadlockAuth::AbstractStrategy)
      config = described_class.build do
        secure_with strategy
        render_on_errors!
      end
      expect(config.handle_auth_errors).to eq(:render)
      expect(config.render_on_errors?).to be(true)
      expect(config.raise_on_errors?).to be(false)
    end

    it "can be configured to raise on errors" do
      strategy = instance_double(PadlockAuth::AbstractStrategy)
      config = described_class.build do
        secure_with strategy
        raise_on_errors!
      end
      expect(config.handle_auth_errors).to eq(:raise)
      expect(config.render_on_errors?).to be(false)
      expect(config.raise_on_errors?).to be(true)
    end

    it "raises an error for an unknown error handling strategy" do
      expect do
        strategy = instance_double(PadlockAuth::AbstractStrategy)
        described_class.build do
          secure_with strategy
          handle_auth_errors(:unknown)
        end
      end.to raise_error(ArgumentError, "handle_auth_errors must be :raise, or :render")
    end
  end
end
