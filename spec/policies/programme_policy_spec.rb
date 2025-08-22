# frozen_string_literal: true

describe ProgrammePolicy do
  describe ProgrammePolicy::Scope do
    describe "#resolve" do
      subject { described_class.new(user, Programme).resolve }

      let(:flu_programme) { create(:programme, :flu) }
      let(:hpv_programme) { create(:programme, :hpv) }

      let(:team) { create(:team, programmes: [flu_programme, hpv_programme]) }

      context "with an admin user" do
        let(:user) { create(:admin, team:) }

        it { should contain_exactly(flu_programme, hpv_programme) }
      end

      context "with a nurse user" do
        let(:user) { create(:nurse, team:) }

        it { should contain_exactly(flu_programme, hpv_programme) }
      end

      context "with a healthcare assistant user" do
        let(:user) { create(:healthcare_assistant, team:) }

        it { should contain_exactly(flu_programme) }
      end
    end
  end
end
