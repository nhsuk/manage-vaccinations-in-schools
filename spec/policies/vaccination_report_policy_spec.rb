# frozen_string_literal: true

describe VaccinationReportPolicy do
  subject(:policy) { described_class }

  let(:poc_only_team) { create(:team, :poc_only) }
  let(:upload_only_team) { create(:team, :upload_only) }
  let(:poc_only_user) { create(:nurse, teams: [poc_only_team]) }
  let(:upload_only_user) { create(:nurse, teams: [upload_only_team]) }
  let(:vaccination_report) { VaccinationReport }

  permissions :create?, :download?, :edit?, :new?, :update? do
    it { should permit(poc_only_user, vaccination_report) }
    it { should_not permit(upload_only_user, vaccination_report) }
  end

  permissions :index?, :destroy?, :show? do
    it { should_not permit(poc_only_user, vaccination_report) }
    it { should_not permit(upload_only_user, vaccination_report) }
  end
end
