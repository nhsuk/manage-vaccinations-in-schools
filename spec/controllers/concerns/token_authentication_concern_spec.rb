# frozen_string_literal: true

describe TokenAuthenticationConcern do
  let(:user) { @user = build(:user) }
  let(:mock_request) { instance_double(request.class, headers: {}) }
  let(:sample_class) do
    Class
      .new do # rubocop:disable Style/BlockDelimiters
        include TokenAuthenticationConcern
        attr_accessor :request, :session

        def authenticate_user!
        end

        def initialize(request: nil, session: {})
          @request = request
          @session = session
        end

        def params
          {}
        end

        def render(content = {}, args = {})
        end

        def current_user
          @user
        end
      end # rubocop:disable Style/MethodCalledOnDoEndBlock
      .new(request: mock_request)
  end

  describe "#jwt_if_given" do
    context "when there is a jwt param" do
      before do
        allow(sample_class).to receive(:params).and_return({ jwt: "myjwt" })
      end

      it "returns the jwt param" do
        expect(sample_class.send(:jwt_if_given)).to eq("myjwt")
      end
    end

    context "when there is no jwt param" do
      context "but there is an Authorization header" do
        before do
          sample_class.request =
            instance_double(
              request.class,
              headers: {
                "Authorization" => "Bearer myjwt"
              }
            )
        end

        it "returns the value of the Authorization header, without the leading 'Bearer'" do
          result = sample_class.send(:jwt_if_given)
          expect(result).to eq("myjwt")
        end
      end

      context "and there is no Authorization header" do
        it "returns nil" do
          expect(sample_class.send(:jwt_if_given)).to be_nil
        end
      end
    end
  end

  describe "#authenticate_app_by_client_id!" do
    let(:client_id) { "something" }

    context "when the :reporting_api feature flag is enabled" do
      before { Flipper.enable(:reporting_api) }

      context "and the client_id param is provided" do
        before do
          allow(sample_class).to receive(:params).and_return(
            { client_id: client_id }.with_indifferent_access
          )
        end

        context "and the client_id param contains the reporting app's client_id" do
          let(:client_id) { Settings.reporting_api.client_app.client_id }

          it "does not cause a token error" do
            expect(sample_class).not_to receive(:client_id_error!)
            sample_class.send(:authenticate_app_by_client_id!)
          end
        end

        context "and the client_id param does not contain the reporting app client_id" do
          it "causes a token error" do
            expect(sample_class).to receive(:client_id_error!)
            sample_class.send(:authenticate_app_by_client_id!)
          end
        end
      end
    end
  end

  describe "#client_id_error!" do
    context "given an empty token" do
      let(:token) { "" }

      it "renders a invalid_request error, with status :unauthorized" do
        expect(sample_class).to receive(:render).with(
          json: {
            errors: "invalid_request"
          },
          status: :unauthorized
        )
        sample_class.send(:client_id_error!, token)
      end
    end

    context "given a token that is not empty, but does not match the reporting app's client_id" do
      let(:token) { "unmatched token" }

      it "renders a unauthorized_client error, with status forbidden" do
        expect(sample_class).to receive(:render).with(
          json: {
            errors: "unauthorized_client"
          },
          status: :forbidden
        )
        sample_class.send(:client_id_error!, token)
      end
    end
  end

  describe "#authenticate_user_by_jwt!" do
    let(:jwt) { "" }
    let(:user_id) { 0 }
    let(:session_token) { "123456abcdef" }
    let(:reporting_api_session_token) { "0987654321123456abcdef" }

    let(:user) do
      create(
        :user,
        session_token: session_token,
        reporting_api_session_token: reporting_api_session_token
      )
    end

    before do
      sample_class.request =
        instance_double(request.class, headers: { "Authorization" => jwt })
    end

    context "when a valid jwt is given" do
      let(:jwt) { "validjwt" }
      let(:user_info) do
        [
          {
            "data" => {
              "user" => {
                "id" => user_id,
                "session_token" => session_token,
                "reporting_api_session_token" => reporting_api_session_token
              },
              "cis2_info" => {
                "some_key" => "some value"
              }
            }
          }
        ]
      end

      before do
        allow(sample_class).to receive(:decode_jwt!).with(jwt).and_return(
          user_info
        )
        allow(sample_class).to receive(:authenticate_user!)
      end

      it "decodes the JWT" do
        expect(sample_class).to receive(:decode_jwt!).with(jwt)
        sample_class.send(:authenticate_user_by_jwt!)
      end

      context "when a User exists with the values of id, session_token and reporting_api_session_token" do
        let(:user_id) { user.id }

        it "copies the user key into session['user']" do
          sample_class.send(:authenticate_user_by_jwt!)
          expect(sample_class.session["user"]).to eq(
            user_info.first["data"]["user"]
          )
        end

        it "copies the cis2_info key into session['cis2_info']" do
          sample_class.send(:authenticate_user_by_jwt!)
          expect(sample_class.session["cis2_info"]).to eq(
            user_info.first["data"]["cis2_info"]
          )
        end

        it "calls authenticate_user!" do
          expect(sample_class).to receive(:authenticate_user!)
          sample_class.send(:authenticate_user_by_jwt!)
        end
      end

      context "when a User does not exist with the values of id, session_token and reporting_api_session_token" do
        let(:user_id) { user.id }

        before do
          user.update!(
            session_token: "someothersessiontoken",
            reporting_api_session_token: "someotherpwdauthsessiontoken"
          )
          sample_class.session = {
            user_id: user.id,
            some_other_session_var: "some value"
          }
        end

        it "clears the session" do
          sample_class.send(:authenticate_user_by_jwt!)
          expect(sample_class.session).to be_empty
        end

        it "calls client_id_error!" do
          expect(sample_class).to receive(:client_id_error!)
          sample_class.send(:authenticate_user_by_jwt!)
        end
      end
    end

    context "when a valid jwt is not given" do
      it "causes a client_id_error!" do
        expect(sample_class).to receive(:client_id_error!)
        sample_class.send(:authenticate_user_by_jwt!)
      end
    end
  end

  describe "decode_jwt!" do
    context "given a jwt" do
      let(:jwt) { "somejwt" }
      let(:decoded_jwt) do
        { "some_key" => { "some nested_key" => "some nested value" } }
      end

      it "tries to decode it with the mavis reporting app secret" do
        expect(JWT).to receive(:decode).with(
          jwt,
          Settings.reporting_api.client_app.secret,
          true,
          { algorithm: "HS512" }
        ) #.and_return(decoded_jwt)
        sample_class.send(:decode_jwt!, jwt)
      end

      context "when decoding works" do
        before do
          allow(JWT).to receive(:decode).with(
            jwt,
            Settings.reporting_api.client_app.secret,
            true,
            { algorithm: "HS512" }
          ).and_return(decoded_jwt)
        end

        it "returns the decoded JWT" do
          expect(sample_class.send(:decode_jwt!, jwt)).to eq(decoded_jwt)
        end
      end

      context "when decoding does not work" do
        it "raises an exception" do
          expect { sample_class.send(:decode_jwt!, jwt) }.to raise_error(
            JWT::DecodeError
          )
        end
      end
    end
  end
end
