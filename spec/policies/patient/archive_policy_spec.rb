# frozen_string_literal: true

describe Patient::ArchivePolicy do
  subject(:policy) { described_class }

  let(:poc_only_team) { create(:team, :poc_only) }
  let(:national_reporting_team) { create(:team, :national_reporting) }
  let(:poc_only_user) { create(:nurse, teams: [poc_only_team]) }
  let(:national_reporting_user) do
    create(:nurse, teams: [national_reporting_team])
  end
  let(:patient) { create(:patient) }

  permissions :new?, :create? do
    it { should permit(poc_only_user, patient) }
    it { should_not permit(national_reporting_user, patient) }
  end

  permissions :index?, :destroy?, :edit?, :show?, :update? do
    it { should_not permit(poc_only_user, patient) }
    it { should_not permit(national_reporting_user, patient) }
  end
end
