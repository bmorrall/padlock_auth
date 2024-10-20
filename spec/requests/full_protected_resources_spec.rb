require "rails_helper"

RSpec.describe "FullProtectedResources", type: :request do
  describe "GET /full_protected_resources", :aggregate_failures do
    # FullProtectedResources#index is protected by padlock_authorize! without any scopes

    context "with a token strategy" do
      let(:secret_key) { SecureRandom.hex(32) }

      before do
        secure_with_token_strategy! secret_key
      end

      it "accepts access tokens provided by an Authorization Header" do
        get "/full_protected_resources",
          headers: {"Authorization" => "Bearer #{secret_key}"}

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq("index")
        expect(headers["WWW-Authenticate"]).to be_nil
      end

      it "accepts access tokens provided by an access_token query parameter" do
        get "/full_protected_resources?access_token=#{secret_key}"

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq("index")
        expect(headers["WWW-Authenticate"]).to be_nil
      end

      it "accepts access tokens provided by an bearer_token query parameter" do
        get "/full_protected_resources?bearer_token=#{secret_key}"

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq("index")
        expect(headers["WWW-Authenticate"]).to be_nil
      end

      it "rejects requests that do not match the secret key" do
        invalid_token = secret_key.reverse

        get "/full_protected_resources",
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
        get "/full_protected_resources"

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body).to match(
          "error" => "invalid_grant",
          "error_description" => "The access token is invalid."
        )
        expect(headers["Cache-Control"]).to eq "no-store"
        expect(headers["WWW-Authenticate"]).to eq 'Bearer realm="PadlockAuth", error="invalid_grant", error_description="The access token is invalid."'
      end
    end

    context "with a token strategy configured with default scopes" do
      let(:secret_key) { SecureRandom.hex(32) }

      before do
        secure_with_token_strategy! secret_key, default_scopes: "admin"
      end

      it "forbids matching tokens" do
        expect do
          get "/full_protected_resources",
            headers: {"Authorization" => "Bearer #{secret_key}"}
        end.to output("[PADLOCK_AUTH] PadlockAuth::Token::AccessToken does not permit any required scopes\n").to_stderr

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body).to match(
          "error" => "invalid_scope",
          "error_description" => "The access token is forbidden."
        )
        expect(headers["Cache-Control"]).to eq "no-store"
        expect(headers["WWW-Authenticate"]).to be_nil
      end
    end

    context "with a token strategy configured with default scopes and handle_auth_errors set to raise" do
      let(:secret_key) { SecureRandom.hex(32) }

      before do
        secure_with_token_strategy! secret_key, default_scopes: "admin", handle_auth_errors: :raise
      end

      it "raises an InvalidToken error for invalid tokens" do
        invalid_token = secret_key.reverse

        expect do
          get "/full_protected_resources",
            headers: {"Authorization" => "Bearer #{invalid_token}"}
        end.to raise_error do |error|
          expect(error).to be_a(PadlockAuth::Errors::InvalidToken)
          expect(error.message).to eq("The access token is invalid.")
          expect(error.response).to be_a(PadlockAuth::Http::InvalidTokenResponse)
        end
      end

      it "raises an TokenForbidden error for matching tokens" do
        expect do
          expect do
            get "/full_protected_resources",
              headers: {"Authorization" => "Bearer #{secret_key}"}
          end.to output("[PADLOCK_AUTH] PadlockAuth::Token::AccessToken does not permit any required scopes\n").to_stderr
        end.to raise_error do |error|
          expect(error).to be_a(PadlockAuth::Errors::TokenForbidden)
          expect(error.message).to eq("The access token is forbidden.")
          expect(error.response).to be_a(PadlockAuth::Http::ForbiddenTokenResponse)
        end
      end
    end
  end

  describe "GET /full_protected_resources/1.json", :aggregate_failures do
    # FullProtectedResources#show is protected by padlock_authorize! with :admin and :write scopes

    context "with a token strategy" do
      let(:secret_key) { SecureRandom.hex(32) }

      before do
        secure_with_token_strategy! secret_key
      end

      it "forbids tokens due to the defined scopes" do
        expect do
          get "/full_protected_resources/1.json",
            headers: {"Authorization" => "Bearer #{secret_key}"}
        end.to output("[PADLOCK_AUTH] PadlockAuth::Token::AccessToken does not permit any required scopes\n").to_stderr

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body).to match(
          "error" => "invalid_scope",
          "error_description" => "The access token is forbidden."
        )
        expect(headers["Cache-Control"]).to eq "no-store"
        expect(headers["WWW-Authenticate"]).to be_nil
      end
    end
  end
end
