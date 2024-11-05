require "rails_helper"

RSpec.describe "PadlockAuthorizedController", type: :controller do
  let(:valid_access_token) { instance_double(PadlockAuth::AbstractAccessToken, acceptable?: true) }

  let(:invalid_access_token) { instance_double(PadlockAuth::AbstractAccessToken, acceptable?: false, accessible?: false, invalid_token_reason: :unknown) }

  let(:expired_access_token) { instance_double(PadlockAuth::AbstractAccessToken, acceptable?: false, accessible?: false, invalid_token_reason: :expired) }

  let(:revoked_access_token) { instance_double(PadlockAuth::AbstractAccessToken, acceptable?: false, accessible?: false, invalid_token_reason: :revoked) }

  let(:forbidden_access_token) { instance_double(PadlockAuth::AbstractAccessToken, acceptable?: false, accessible?: true, includes_scope?: false, forbidden_token_reason: :missing_scope) }

  controller do
    before_action :padlock_authorize!

    def index
      render plain: "index"
    end
  end

  describe "default configuration" do
    let(:strategy) { instance_double(PadlockAuth::AbstractStrategy) }

    before :each do
      configured_strategy = strategy
      PadlockAuth.configure do
        secure_with configured_strategy
      end
    end

    it "allows valid tokens from the Authorization header" do
      expect(strategy).to receive(:build_access_token).with("1A2BC3").and_return(valid_access_token)

      request.env["HTTP_AUTHORIZATION"] = "Bearer 1A2BC3"

      get :index

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("index")
    end

    it "allows valid tokens from the access_token param" do
      expect(strategy).to receive(:build_access_token).with("1A2BC3").and_return(valid_access_token)

      get :index, params: {access_token: "1A2BC3"}

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("index")
    end

    it "allows valid tokens from the bearer_token param" do
      expect(strategy).to receive(:build_access_token).with("1A2BC3").and_return(valid_access_token)

      get :index, params: {bearer_token: "1A2BC3"}

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("index")
    end

    it "rejects requests without a token" do
      expect(strategy).not_to receive(:build_access_token)
      expect(strategy).to receive_build_invalid_token_response

      get :index

      expect(response).to have_http_status(:unauthorized)
      expect(response.body).not_to eq("index")
    end

    it "rejects invalid access tokens" do
      expect(strategy).to receive(:build_access_token).with("1A2BC3").and_return(invalid_access_token)
      expect(strategy).to receive_build_invalid_token_response

      get :index, params: {access_token: "1A2BC3"}

      expect(response).to have_http_status(:unauthorized)
      expect(response.body).not_to eq("index")
    end

    it "rejects expired access tokens" do
      expect(strategy).to receive(:build_access_token).with("1A2BC3").and_return(expired_access_token)
      expect(strategy).to receive_build_invalid_token_response

      get :index, params: {access_token: "1A2BC3"}

      expect(response).to have_http_status(:unauthorized)
      expect(response.body).not_to eq("index")
    end

    it "rejects revoked access tokens" do
      expect(strategy).to receive(:build_access_token).with("1A2BC3").and_return(revoked_access_token)
      expect(strategy).to receive_build_invalid_token_response

      get :index, params: {access_token: "1A2BC3"}

      expect(response).to have_http_status(:unauthorized)
      expect(response.body).not_to eq("index")
    end

    it "rejects forbidden access tokens" do
      expect(strategy).to receive(:build_access_token).with("1A2BC3").and_return(forbidden_access_token)
      expect(strategy).to receive_build_forbidden_token_response

      get :index, params: {access_token: "1A2BC3"}

      expect(response).to have_http_status(:forbidden)
      expect(response.body).not_to eq("index")
    end
  end

  describe "when configured for bearer authentication only" do
    let(:strategy) { instance_double(PadlockAuth::AbstractStrategy) }

    before :each do
      configured_strategy = strategy
      PadlockAuth.configure do
        secure_with configured_strategy

        access_token_methods :from_bearer_authorization
      end
    end

    it "allows valid tokens from the Authorization header" do
      expect(strategy).to receive(:build_access_token).with("1A2BC3").and_return(valid_access_token)

      request.env["HTTP_AUTHORIZATION"] = "Bearer 1A2BC3"

      get :index

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("index")
    end

    it "rejects invalid tokens from the Authorization header" do
      expect(strategy).to receive(:build_access_token).with("1AB2C3").and_return(invalid_access_token)
      expect(strategy).to receive_build_invalid_token_response

      request.env["HTTP_AUTHORIZATION"] = "Bearer 1AB2C3"

      get :index

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects requests with the access_token param" do
      expect(strategy).not_to receive(:build_access_token)
      expect(strategy).to receive_build_invalid_token_response

      get :index, params: {access_token: "1A2BC3"}

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects requests with the bearer_token param" do
      expect(strategy).not_to receive(:build_access_token)
      expect(strategy).to receive_build_invalid_token_response

      get :index, params: {bearer_token: "1A2BC3"}

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "when configured for http basic access authorisation" do
    let(:strategy) { instance_double(PadlockAuth::AbstractStrategy) }

    before :each do
      configured_strategy = strategy
      PadlockAuth.configure do
        secure_with configured_strategy

        access_token_methods :from_basic_authorization
      end
    end

    it "allows valid access tokens from Basic Authorization credentials" do
      expect(strategy).to receive(:build_access_token_from_credentials).with("username", "password").and_return(valid_access_token)

      encoded_credentials = ActionController::HttpAuthentication::Basic.encode_credentials("username", "password")
      request.env["HTTP_AUTHORIZATION"] = encoded_credentials

      get :index

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("index")
    end

    it "rejects invalid access tokens from Basic Authorization credentials" do
      expect(strategy).to receive(:build_access_token_from_credentials).with("username", "password").and_return(invalid_access_token)
      expect(strategy).to receive_build_invalid_token_response

      encoded_credentials = ActionController::HttpAuthentication::Basic.encode_credentials("username", "password")
      request.env["HTTP_AUTHORIZATION"] = encoded_credentials

      get :index

      expect(response).to have_http_status(:unauthorized)
    end

    it "forbids forbidden access tokens from Basic Authorization credentials" do
      expect(strategy).to receive(:build_access_token_from_credentials).with("username", "password").and_return(forbidden_access_token)
      expect(strategy).to receive_build_forbidden_token_response

      encoded_credentials = ActionController::HttpAuthentication::Basic.encode_credentials("username", "password")
      request.env["HTTP_AUTHORIZATION"] = encoded_credentials

      get :index

      expect(response).to have_http_status(:forbidden)
    end

    it "rejects requests with a Bearer Authorization header" do
      expect(strategy).not_to receive(:build_access_token_from_credentials)
      expect(strategy).to receive_build_invalid_token_response

      request.env["HTTP_AUTHORIZATION"] = "Bearer 1A2BC3"

      get :index

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "when configured with a custom access method" do
    let(:strategy) { instance_double(PadlockAuth::AbstractStrategy) }
    let(:access_token) { instance_double(PadlockAuth::AbstractAccessToken, acceptable?: true) }

    before :each do
      configured_strategy = strategy
      PadlockAuth.configure do
        secure_with configured_strategy

        access_token_methods ->(request) { request.params[:custom_access_token] }
      end
    end

    it "allows valid tokens from the custom access method" do
      expect(strategy).to receive(:build_access_token).with("1A2BC3").and_return(valid_access_token)

      get :index, params: {custom_access_token: "1A2BC3"}

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("index")
    end

    it "rejects invalid tokens from the custom access method" do
      expect(strategy).to receive(:build_access_token).with("1A2BC3").and_return(invalid_access_token)
      expect(strategy).to receive_build_invalid_token_response

      get :index, params: {custom_access_token: "1A2BC3"}

      expect(response).to have_http_status(:unauthorized)
    end

    it "forbids forbidden tokens from the custom access method" do
      expect(strategy).to receive(:build_access_token).with("1A2BC3").and_return(forbidden_access_token)
      expect(strategy).to receive_build_forbidden_token_response

      get :index, params: {custom_access_token: "1A2BC3"}

      expect(response).to have_http_status(:forbidden)
    end

    it "rejects requests without a token" do
      expect(strategy).not_to receive(:build_access_token)
      expect(strategy).to receive_build_invalid_token_response

      get :index, params: {custom_access_token: nil}

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "when configured with raise on errors" do
    let(:strategy) { instance_double(PadlockAuth::AbstractStrategy) }

    before :each do
      configured_strategy = strategy
      PadlockAuth.configure do
        secure_with configured_strategy

        raise_on_errors!
      end
    end

    it "allows valid tokens" do
      expect(strategy).to receive(:build_access_token).with("1A2BC3").and_return(valid_access_token)

      get :index, params: {access_token: "1A2BC3"}

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("index")
    end

    it "raises an exception for invalid tokens" do
      expect(strategy).to receive(:build_access_token).with("1A2BC3").and_return(invalid_access_token)
      expect(strategy).to receive_build_invalid_token_response

      expect do
        get :index, params: {access_token: "1A2BC3"}
      end.to raise_error do |error|
        expect(error).to be_a(PadlockAuth::Errors::InvalidToken)
        expect(error.message).to eq("The access token is invalid.")
      end
    end

    it "raises an exception for expired tokens" do
      expect(strategy).to receive(:build_access_token).with("1A2BC3").and_return(expired_access_token)
      expect(strategy).to receive_build_invalid_token_response

      expect do
        get :index, params: {access_token: "1A2BC3"}
      end.to raise_error do |error|
        expect(error).to be_a(PadlockAuth::Errors::TokenExpired)
        expect(error.message).to eq("The access token has expired.")
      end
    end

    it "raises an exception for revoked tokens" do
      expect(strategy).to receive(:build_access_token).with("1A2BC3").and_return(revoked_access_token)
      expect(strategy).to receive_build_invalid_token_response

      expect do
        get :index, params: {access_token: "1A2BC3"}
      end.to raise_error do |error|
        expect(error).to be_a(PadlockAuth::Errors::TokenRevoked)
        expect(error.message).to eq("The access token was revoked.")
      end
    end

    it "raises an exception for forbidden tokens" do
      expect(strategy).to receive(:build_access_token).with("1A2BC3").and_return(forbidden_access_token)
      expect(forbidden_access_token).to receive(:forbidden_token_reason).and_return(:forbidden)
      expect(strategy).to receive_build_forbidden_token_response

      expect do
        get :index, params: {access_token: "1A2BC3"}
      end.to raise_error do |error|
        expect(error).to be_a(PadlockAuth::Errors::TokenForbidden)
        expect(error.message).to eq("The access token is forbidden.")
      end
    end
  end

  describe "when a controller has custom unauthorized render options" do
    let(:strategy) { instance_double(PadlockAuth::AbstractStrategy) }

    before :each do
      configured_strategy = strategy
      PadlockAuth.configure do
        secure_with configured_strategy
      end
    end

    controller do
      before_action :padlock_authorize!

      def index
        render plain: "index"
      end

      def padlock_auth_unauthorized_render_options(error:)
        {plain: error.description, layout: false}
      end
    end

    it "renders the custom error options when no access token is found" do
      expect(strategy).not_to receive(:build_access_token)
      expect(strategy).to receive_build_invalid_token_response

      get :index

      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to eq("The access token is invalid.")
    end

    it "renders the custom error options when an invalid access token is found" do
      expect(strategy).to receive(:build_access_token).with("1A2BC3").and_return(invalid_access_token)
      expect(strategy).to receive_build_invalid_token_response

      get :index, params: {access_token: "1A2BC3"}

      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to eq("The access token is invalid.")
    end

    it "renders the custom error options when an expired access token is found" do
      expect(strategy).to receive(:build_access_token).with("1A2BC3").and_return(expired_access_token)
      expect(strategy).to receive_build_invalid_token_response

      get :index, params: {access_token: "1A2BC3"}

      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to eq("The access token has expired.")
    end

    it "renders the custom error options when a revoked access token is found" do
      expect(strategy).to receive(:build_access_token).with("1A2BC3").and_return(revoked_access_token)
      expect(strategy).to receive_build_invalid_token_response

      get :index, params: {access_token: "1A2BC3"}

      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to eq("The access token was revoked.")
    end
  end

  context "when a controller has custom forbidden render options" do
    let(:strategy) { instance_double(PadlockAuth::AbstractStrategy) }

    before :each do
      configured_strategy = strategy
      PadlockAuth.configure do
        secure_with configured_strategy

        default_scopes :admin
      end
    end

    controller do
      before_action :padlock_authorize!

      def index
        render plain: "index"
      end

      def padlock_auth_forbidden_render_options(error:)
        {plain: error.description}
      end
    end

    it "renders the custom error options for a forbidden access token" do
      expect(strategy).to receive(:build_access_token).with("my$ecretK3y").and_return(forbidden_access_token)
      expect(strategy).to receive_build_forbidden_token_response

      get :index, params: {access_token: "my$ecretK3y"}

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to eq('Access to this resource requires scope "admin".')
    end
  end

  context "when a controller has custom forbiiden render options with render not found when forbidden" do
    let(:strategy) { instance_double(PadlockAuth::AbstractStrategy) }

    before :each do
      configured_strategy = strategy
      PadlockAuth.configure do
        secure_with configured_strategy
      end
    end

    controller do
      before_action :padlock_authorize!

      def index
        render plain: "index"
      end

      def padlock_auth_forbidden_render_options(error:)
        {respond_not_found_when_forbidden: true}
      end
    end

    it "responds with unauthorized for a invalid access token" do
      expect(strategy).to receive(:build_access_token).with("my$ecretK3y").and_return(invalid_access_token)
      expect(strategy).to receive_build_invalid_token_response

      get :index, params: {access_token: "my$ecretK3y"}

      expect(response).to have_http_status(:unauthorized)
    end

    it "renders a 404 for a forbidden access token" do
      expect(strategy).to receive(:build_access_token).with("my$ecretK3y").and_return(forbidden_access_token)
      expect(strategy).to receive_build_forbidden_token_response

      get :index, params: {access_token: "my$ecretK3y"}

      expect(response).to have_http_status(:not_found)
    end
  end

  def receive_build_invalid_token_response
    receive(:build_invalid_token_response) do |*args|
      PadlockAuth::Http::InvalidTokenResponse.from_access_token(*args)
    end
  end

  def receive_build_forbidden_token_response
    receive(:build_forbidden_token_response) do |*args|
      PadlockAuth::Http::ForbiddenTokenResponse.from_access_token(*args)
    end
  end
end
