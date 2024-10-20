require "rails_helper"

RSpec.describe "SemiProtectedResources", type: :request do
  describe "GET /semi_protected_resources", :aggregate_failures do
    # SemiProtectedResources#index is protected by padlock_authorize! without any scopes

    context "with a token strategy" do
      let(:secret_key) { SecureRandom.hex(32) }

      before do
        secure_with_token_strategy! secret_key
      end

      it "accepts access tokens provided by an Authorization Header" do
        get "/semi_protected_resources",
          headers: {"Authorization" => "Bearer #{secret_key}"}

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq("protected index")
        expect(headers["WWW-Authenticate"]).to be_nil
      end

      it "rejects requests that do not match the secret key" do
        invalid_token = secret_key.reverse

        get "/semi_protected_resources",
          headers: {"Authorization" => "Bearer #{invalid_token}"}

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body).to match(
          "error" => "invalid_grant",
          "error_description" => "The access token is invalid."
        )
        expect(headers["Cache-Control"]).to eq "no-store"
        expect(headers["WWW-Authenticate"]).to eq 'Bearer realm="PadlockAuth", error="invalid_grant", error_description="The access token is invalid."'
      end

      it "rejects requests with no token" do
        get "/semi_protected_resources"

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body).to match(
          "error" => "invalid_grant",
          "error_description" => "The access token is invalid."
        )
        expect(headers["Cache-Control"]).to eq "no-store"
        expect(headers["WWW-Authenticate"]).to eq 'Bearer realm="PadlockAuth", error="invalid_grant", error_description="The access token is invalid."'
      end
    end

    context "with a token strategy and handle_auth_errors set to raise" do
      let(:secret_key) { SecureRandom.hex(32) }

      before do
        secure_with_token_strategy! secret_key, handle_auth_errors: :raise
      end

      it "raises an errors for requests that do not match the secret key when handle_auth_errors is set to raise" do
        invalid_token = secret_key.reverse

        expect do
          get "/semi_protected_resources",
            headers: {"Authorization" => "Bearer #{invalid_token}"}
        end.to raise_error do |error|
          expect(error).to be_a(PadlockAuth::Errors::InvalidToken)
          expect(error.message).to eq("The access token is invalid.")
          expect(error.response).to be_a(PadlockAuth::Http::InvalidTokenResponse)
        end
      end
    end
  end

  describe "GET /semi_protected_resources/1.json", :aggregate_failures do
    # SemiProtectedResources#show is not protected by padlock_authorize!

    context "with a token strategy" do
      let(:secret_key) { SecureRandom.hex(32) }

      before do
        secure_with_token_strategy! secret_key
      end

      it "allows requests with a matching access token" do
        get "/semi_protected_resources/1.json",
          headers: {"Authorization" => "Bearer #{secret_key}"}

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq("non protected show")
        expect(headers["WWW-Authenticate"]).to be_nil
      end

      it "allows requests with an invalid access token" do
        invalid_token = secret_key.reverse

        get "/semi_protected_resources/1.json",
          headers: {"Authorization" => "Bearer #{invalid_token}"}

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq("non protected show")
        expect(headers["WWW-Authenticate"]).to be_nil
      end
    end

    context "with a token strategy and default scopes" do
      let(:secret_key) { SecureRandom.hex(32) }

      before do
        secure_with_token_strategy! secret_key, default_scopes: "admin"
      end

      it "allows requests with a valid access token" do
        get "/semi_protected_resources/1.json",
          headers: {"Authorization" => "Bearer #{secret_key}"}

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq("non protected show")
        expect(headers["WWW-Authenticate"]).to be_nil
      end
    end
  end
end
