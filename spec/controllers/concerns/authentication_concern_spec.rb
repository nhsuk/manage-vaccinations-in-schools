# frozen_string_literal: true

# rubocop:disable RSpec/VerifiedDoubles
describe AuthenticationConcern do
  let(:user) { @user = build(:user) }
  let(:sample_class) do
    Class
      .new do # rubocop:disable Style/BlockDelimiters
        include AuthenticationConcern

        def current_user
          @user
        end
      end # rubocop:disable Style/MethodCalledOnDoEndBlock
      .new
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
end
# rubocop:enable RSpec/VerifiedDoubles
