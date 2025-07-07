require "spec_helper"

RSpec.describe OneTimeTokensController do
  let(:user) { create(:user) }
  let(:valid_token) { OneTimeToken.find_or_generate_for!(user_id: user.id) }

  describe "#verify" do
    context "given a valid auth header when auth-by-header is enable" do
      before do
        Flipper.enable(:auth_token_by_header)
        request.headers["Authorization"] = Settings.mavis_reporting_app.secret
      end
      let(:do_the_request) { get :verify, params: { token: token.token }, format: :json }

      context "and a valid OneTimeToken in the token param" do
        let(:token) { valid_token }

        it "responds with 200" do
          do_the_request
          expect(response.status).to eq(200)
        end

        it "deletes the OneTimeToken" do
          do_the_request
          expect(OneTimeToken.exists?(token.id)).to eq(false)
        end

        it "responds with json" do
          do_the_request
          expect(response.headers['Content-type']).to eq('application/json; charset=utf-8')
        end

        describe "the response json" do
          let(:response_json) { JSON.parse(response.body) }
          
          it "includes the one-time-tokens attributes" do
            do_the_request
            expect(response_json).to include(token.attributes.as_json)
          end

          it "includes the user in the 'user' key" do
            do_the_request
            expect(response_json['user']).to include(token.user.as_json)
          end
        end
      end
    end
  end
end