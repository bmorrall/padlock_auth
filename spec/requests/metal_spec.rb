require "rails_helper"

RSpec.describe "Metal" do
  describe "GET /metal", :aggregate_failures do
    context "with a token strategy" do
      let(:secret_key) { SecureRandom.hex(32) }

      before do
        secure_with_token_strategy! secret_key
      end

      it "accepts requests with a valid token" do
        get "/metal.json?access_token=#{secret_key}"

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq({ok: true}.to_json)
      end

      it "rejects requests with an invalid secret_key" do
        invalid_token = secret_key.reverse

        get "/metal.json?access_token=#{invalid_token}"

        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to be_blank
        expect(headers["Cache-Control"]).to eq "no-store"
        expect(headers["WWW-Authenticate"]).to eq 'Bearer realm="PadlockAuth", error="invalid_grant", error_description="The access token is invalid."'
      end

      it "rejects requests without a token" do
        get "/metal.json"

        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to be_blank
        expect(headers["Cache-Control"]).to eq "no-store"
        expect(headers["WWW-Authenticate"]).to eq 'Bearer realm="PadlockAuth", error="invalid_grant", error_description="The access token is invalid."'
      end
    end

    context "with a token strategy and default scopes" do
      let(:secret_key) { SecureRandom.hex(32) }

      before do
        secure_with_token_strategy! secret_key, default_scopes: "admin"
      end

      it "forbids tokens when default scopes is set to any value" do
        expect do
          get "/metal.json?access_token=#{secret_key}"
        end.to output("[PADLOCK_AUTH] PadlockAuth::Token::AccessToken does not permit any required scopes\n").to_stderr

        expect(response).to have_http_status(:forbidden)

        expect(response.body).to be_blank
        expect(headers["Cache-Control"]).to eq "no-store"
        expect(headers["WWW-Authenticate"]).to be_nil
      end
    end
  end
end
