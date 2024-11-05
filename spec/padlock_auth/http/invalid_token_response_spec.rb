require "rails_helper"

RSpec.describe PadlockAuth::Http::InvalidTokenResponse do
  before :each do
    configured_strategy = instance_double(PadlockAuth::AbstractStrategy)
    PadlockAuth.configure do
      secure_with configured_strategy

      realm "PadlockAuth"
    end
  end

  describe ".from_access_token" do
    subject(:response) { described_class.from_access_token(access_token) }

    context "with a :revoked invalid token reason" do
      let(:access_token) { instance_double(PadlockAuth::AbstractAccessToken, invalid_token_reason: :revoked) }

      it { expect(response.name).to eq(:invalid_grant) }
      it { expect(response.reason).to eq(:revoked) }
      it { expect(response.status).to eq(:unauthorized) }
      it { expect(response.description).to eq("The access token was revoked.") }

      it "provides response headers" do
        expect(response.headers).to eq(
          "Cache-Control" => "no-store, no-cache",
          "Content-Type" => "application/json; charset=utf-8",
          "WWW-Authenticate" => %(Bearer realm="PadlockAuth", error="invalid_grant", error_description="The access token was revoked.")
        )
      end

      it "provides a response body" do
        expect(response.body).to eq(
          error: :invalid_grant,
          error_description: "The access token was revoked."
        )
      end

      it "raises a TokenRevoked exception" do
        expect { response.raise_exception! }.to raise_error do |error|
          expect(error).to be_a(PadlockAuth::Errors::TokenRevoked)
          expect(error.message).to eq("The access token was revoked.")
          expect(error.response).to be response
        end
      end
    end

    context "with an :expired invalid token reason" do
      let(:access_token) { instance_double(PadlockAuth::AbstractAccessToken, invalid_token_reason: :expired) }

      it { expect(response.name).to eq(:invalid_grant) }
      it { expect(response.reason).to eq(:expired) }
      it { expect(response.status).to eq(:unauthorized) }
      it { expect(response.description).to eq("The access token has expired.") }

      it "provides response headers" do
        expect(response.headers).to eq(
          "Cache-Control" => "no-store, no-cache",
          "Content-Type" => "application/json; charset=utf-8",
          "WWW-Authenticate" => %(Bearer realm="PadlockAuth", error="invalid_grant", error_description="The access token has expired.")
        )
      end

      it "provides a response body" do
        expect(response.body).to eq(
          error: :invalid_grant,
          error_description: "The access token has expired."
        )
      end

      it "raises a TokenExpired exception" do
        expect { response.raise_exception! }.to raise_error do |error|
          expect(error).to be_a(PadlockAuth::Errors::TokenExpired)
          expect(error.message).to eq("The access token has expired.")
          expect(error.response).to be response
        end
      end
    end

    context "with an :unknown invalid token reason" do
      let(:access_token) { instance_double(PadlockAuth::AbstractAccessToken, invalid_token_reason: :unknown) }

      it { expect(response.name).to eq(:invalid_grant) }
      it { expect(response.reason).to eq(:unknown) }
      it { expect(response.status).to eq(:unauthorized) }
      it { expect(response.description).to eq("The access token is invalid.") }

      it "provides response headers" do
        expect(response.headers).to eq(
          "Cache-Control" => "no-store, no-cache",
          "Content-Type" => "application/json; charset=utf-8",
          "WWW-Authenticate" => %(Bearer realm="PadlockAuth", error="invalid_grant", error_description="The access token is invalid.")
        )
      end

      it "provides a response body" do
        expect(response.body).to eq(
          error: :invalid_grant,
          error_description: "The access token is invalid."
        )
      end

      it "raises a TokenUnknown exception" do
        expect { response.raise_exception! }.to raise_error do |error|
          expect(error).to be_a(PadlockAuth::Errors::TokenUnknown)
          expect(error.message).to eq("The access token is invalid.")
          expect(error.response).to be response
        end
      end
    end

    context "with a nil access token" do
      let(:access_token) { nil }

      it { expect(response.name).to eq(:invalid_grant) }
      it { expect(response.reason).to eq(:unknown) }
      it { expect(response.status).to eq(:unauthorized) }
      it { expect(response.description).to eq("The access token is invalid.") }

      it "provides response headers" do
        expect(response.headers).to eq(
          "Cache-Control" => "no-store, no-cache",
          "Content-Type" => "application/json; charset=utf-8",
          "WWW-Authenticate" => %(Bearer realm="PadlockAuth", error="invalid_grant", error_description="The access token is invalid.")
        )
      end

      it "provides a response body" do
        expect(response.body).to eq(
          error: :invalid_grant,
          error_description: "The access token is invalid."
        )
      end

      it "raises a TokenUnknown exception" do
        expect { response.raise_exception! }.to raise_error do |error|
          expect(error).to be_a(PadlockAuth::Errors::TokenUnknown)
          expect(error.message).to eq("The access token is invalid.")
          expect(error.response).to be response
        end
      end
    end
  end
end
