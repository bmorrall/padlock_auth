require "rails_helper"

RSpec.describe PadlockAuth::Http::ForbiddenTokenResponse do
  before :each do
    configured_strategy = instance_double(PadlockAuth::AbstractStrategy)
    PadlockAuth.configure do
      secure_with configured_strategy

      realm "PadlockAuth"
    end
  end

  describe ".from_access_token" do
    subject(:response) { described_class.from_access_token(access_token, PadlockAuth::Config::Scopes.from_array("foo", "bar", "baz")) }

    context "with a :missing_scope forbidden token reason" do
      let(:access_token) { instance_double(PadlockAuth::AbstractAccessToken, forbidden_token_reason: :missing_scope) }

      it { expect(response.name).to eq(:invalid_scope) }
      it { expect(response.reason).to eq(:missing_scope) }
      it { expect(response.status).to eq(:forbidden) }
      it { expect(response.description).to eq('Access to this resource requires scope "foo bar baz".') }

      it "provides response headers" do
        expect(response.headers).to eq(
          "Cache-Control" => "no-store, no-cache",
          "Content-Type" => "application/json; charset=utf-8"
        )
      end

      it "provides a response body" do
        expect(response.body).to eq(
          error: :invalid_scope,
          error_description: 'Access to this resource requires scope "foo bar baz".'
        )
      end

      it "raises a TokenForbidden exception" do
        expect { response.raise_exception! }.to raise_error do |error|
          expect(error).to be_a(PadlockAuth::Errors::TokenForbidden)
          expect(error.message).to eq('Access to this resource requires scope "foo bar baz".')
          expect(error.response).to be response
        end
      end
    end

    context "with an :unknown forbidden token reason" do
      let(:access_token) { instance_double(PadlockAuth::AbstractAccessToken, forbidden_token_reason: :unknown) }

      it { expect(response.name).to eq(:invalid_scope) }
      it { expect(response.reason).to eq(:unknown) }
      it { expect(response.status).to eq(:forbidden) }
      it { expect(response.description).to eq("The access token is forbidden.") }

      it "provides response headers" do
        expect(response.headers).to eq(
          "Cache-Control" => "no-store, no-cache",
          "Content-Type" => "application/json; charset=utf-8"
        )
      end

      it "provides a response body" do
        expect(response.body).to eq(
          error: :invalid_scope,
          error_description: "The access token is forbidden."
        )
      end

      it "raises a TokenForbidden exception" do
        expect do
          response.raise_exception!
        end.to raise_error do |error|
          expect(error).to be_a(PadlockAuth::Errors::TokenForbidden)
          expect(error.message).to eq("The access token is forbidden.")
          expect(error.response).to be response
        end
      end
    end

    context "with a nil access token" do
      let(:access_token) { nil }

      it { expect(response.name).to eq(:invalid_scope) }
      it { expect(response.reason).to eq(:unknown) }
      it { expect(response.status).to eq(:forbidden) }
      it { expect(response.description).to eq("The access token is forbidden.") }

      it "provides response headers" do
        expect(response.headers).to eq(
          "Cache-Control" => "no-store, no-cache",
          "Content-Type" => "application/json; charset=utf-8"
        )
      end

      it "provides a response body" do
        expect(response.body).to eq(
          error: :invalid_scope,
          error_description: "The access token is forbidden."
        )
      end

      it "raises a TokenForbidden exception" do
        expect { response.raise_exception! }.to raise_error do |error|
          expect(error).to be_a(PadlockAuth::Errors::TokenForbidden)
          expect(error.message).to eq("The access token is forbidden.")
          expect(error.response).to be response
        end
      end
    end
  end
end
