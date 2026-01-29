# frozen_string_literal: true

describe ConsentPolicy do
  subject(:policy) { described_class }

  let(:poc_only_team) { create(:team, :poc_only) }
  let(:national_reporting_team) { create(:team, :national_reporting) }
  let(:poc_only_user) { create(:nurse, teams: [poc_only_team]) }
  let(:national_reporting_user) do
    create(:nurse, teams: [national_reporting_team])
  end
  let(:consent) { create(:consent) }

  permissions :index?, :create?, :edit?, :new?, :show?, :update? do
    it { should permit(poc_only_user, consent) }
    it { should_not permit(national_reporting_user, consent) }
  end

  permissions :destroy? do
    it { should_not permit(poc_only_user, consent) }
    it { should_not permit(national_reporting_user, consent) }
  end
end
