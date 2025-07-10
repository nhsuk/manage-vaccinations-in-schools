# frozen_string_literal: true

# rubocop:disable RSpec/VerifiedDoubles
describe AuthenticationConcern do
  let(:user) { @user = build(:user) }
  let(:mock_request) { instance_double("request", headers: {}) }
  let(:sample_class) do
    Class
      .new do # rubocop:disable Style/BlockDelimiters
        include AuthenticationConcern
        attr_accessor :request

        def initialize(request: nil)
          @request = request
        end

        def params
          {}
        end

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

  describe "#jwt_if_given" do
    context "when there is a jwt param" do
      before do
        allow(sample_class).to receive(:params).and_return( {jwt: "myjwt"} )
      end

      it "returns the jwt param" do
        expect(sample_class.send(:jwt_if_given)).to eq("myjwt")
      end
    end

    context "when there is no jwt param" do
      context "but there is an Authorization header" do
        before do
          sample_class.request = instance_double('request', headers: {'Authorization' => "Bearer myjwt"} )
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
end
# rubocop:enable RSpec/VerifiedDoubles
