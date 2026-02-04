# frozen_string_literal: true

describe VaccinationReportPolicy do
  subject(:policy) { described_class }

  let(:point_of_care_team) { create(:team, :point_of_care) }
  let(:national_reporting_team) { create(:team, :national_reporting) }
  let(:point_of_care_user) { create(:nurse, teams: [point_of_care_team]) }
  let(:national_reporting_user) do
    create(:nurse, teams: [national_reporting_team])
  end
  let(:vaccination_report) { VaccinationReport }

  permissions :create?, :download?, :edit?, :new?, :update? do
    it { should permit(point_of_care_user, vaccination_report) }
    it { should_not permit(national_reporting_user, vaccination_report) }
  end

  permissions :index?, :destroy?, :show? do
    it { should_not permit(point_of_care_user, vaccination_report) }
    it { should_not permit(national_reporting_user, vaccination_report) }
  end
end
