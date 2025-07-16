# frozen_string_literal: true

# rubocop:disable RSpec/VerifiedDoubles
describe AuthenticationConcern do
  let(:user) { @user = build(:user) }
  let(:mock_request) { instance_double("request", headers: {}) }
  let(:sample_class) do
    Class
      .new do # rubocop:disable Style/BlockDelimiters
        include AuthenticationConcern
        attr_accessor :request, :session

        def initialize(request: nil, session: {})
          @request = request
          @session = session
        end

        def params
          {}
        end

        def render( content={}, args={} ); end

        def current_user
          @user
        end
      end # rubocop:disable Style/MethodCalledOnDoEndBlock
      .new(request: mock_request)
  end

  describe "set_user_cis2_info" do
    let(:user) { build(:user, cis2_info: nil) }

    context "when cis2 is disabled" do
      it "does not set the user's cis2_info" do
        allow(Settings).to receive(:cis2).and_return(double(enabled: false))

        sample_class.send(:set_user_cis2_info)

        expect(user.cis2_info).to be_nil
      end
    end

    context "when cis2 is enabled" do
      it "does not set the user's cis2_info" do
        allow(Settings).to receive(:cis2).and_return(double(enabled: true))

        sample_class.send(:set_user_cis2_info)

        expect(user.cis2_info).to be_nil
      end
    end
  end

  

# The commented out code block you provided is a pending RSpec example group for a method called
# `#add_token_to`. This method is expected to find or generate a `OneTimeToken` for a given user with
# the `cis2_info` from the current session. The example group contains two contexts:
  describe "#add_token_to" do
    let(:user) { create(:user) }
    let(:token) { build(:one_time_token, user: user, token: "mytoken") }
    let(:url) { "/some/relative/path.json" }
    let(:session_cis2_info) { {'some_key' => 'some value'} }

    before do
      sample_class.session = {'cis2_info' => session_cis2_info}
      allow(OneTimeToken).to receive(:find_or_generate_for!).with(user_id: user.id, cis2_info: session_cis2_info).and_return(token)
    end
    
    it "finds or generates a OneTimeToken for the given user with the cis2_info from the current session" do
      expect(OneTimeToken).to receive(:find_or_generate_for!).with(user_id: user.id, cis2_info: session_cis2_info).and_return(token)
      sample_class.send(:add_token_to, url, user)
    end

    context "given a url with no params" do
      let(:url) { "/some/relative/path.json" }

      it "adds the token param as a query string" do
        expect(sample_class.send(:add_token_to, url, user)).to eq("/some/relative/path.json?token=mytoken")
      end
    end

    context "given a url with some params already" do
      let(:url) { "/some/relative/path.json?q=some%20search" }

      it "adds the token param as a query string" do
        expect(sample_class.send(:add_token_to, url, user)).to eq("/some/relative/path.json?q=some%20search&token=mytoken")
      end
    end
  end

  describe "reporting_app_redirect_url_with_token_for" do
    let(:session_cis2_info) { {'some_key' => 'some value' } }
    let(:token) { build(:one_time_token, user: user, token: "mytoken") }
    let(:result) { sample_class.send(:reporting_app_redirect_url_with_token_for, user) }

    context "when there is a redirect_after_login key in session" do
      before do
         allow(OneTimeToken).to receive(:find_or_generate_for!).with(user_id: user.id, cis2_info: session_cis2_info).and_return(token)
        sample_class.session = {'redirect_after_login' => "http://reporting.mavis:5555/path?some_param=some%20value", 'cis2_info' => session_cis2_info}
      end

      it "returns that URL with a token added to it for the given user" do
        
        expect(result).to eq("http://reporting.mavis:5555/path?some_param=some%20value&token=mytoken")
      end
    end

    context "when there is no redirect_after_login key in session" do
      before do
        sample_class.session = {'cis2_info' => session_cis2_info}
      end

      it "returns nil" do
        expect(result).to be_nil
      end
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubles
