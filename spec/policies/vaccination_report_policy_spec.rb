# frozen_string_literal: true

describe VaccinationReportPolicy do
  subject(:policy) { described_class }

  let(:poc_only_team) { create(:team, :poc_only) }
  let(:national_reporting_team) { create(:team, :national_reporting) }
  let(:poc_only_user) { create(:nurse, teams: [poc_only_team]) }
  let(:national_reporting_user) do
    create(:nurse, teams: [national_reporting_team])
  end
  let(:vaccination_report) { VaccinationReport }

  permissions :create?, :download?, :edit?, :new?, :update? do
    it { should permit(poc_only_user, vaccination_report) }
    it { should_not permit(national_reporting_user, vaccination_report) }
  end

  permissions :index?, :destroy?, :show? do
    it { should_not permit(poc_only_user, vaccination_report) }
    it { should_not permit(national_reporting_user, vaccination_report) }
  end
end
