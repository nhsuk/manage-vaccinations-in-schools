# frozen_string_literal: true

describe SchoolMoveExportPolicy do
  subject(:policy) { described_class }

  let(:poc_only_team) { create(:team, :poc_only) }
  let(:national_reporting_team) { create(:team, :national_reporting) }
  let(:poc_only_user) { create(:nurse, teams: [poc_only_team]) }
  let(:national_reporting_user) do
    create(:nurse, teams: [national_reporting_team])
  end
  let(:school_move_export) { SchoolMoveExport }

  permissions :index?, :create?, :download?, :edit?, :new?, :show?, :update? do
    it { should permit(poc_only_user, school_move_export) }
    it { should_not permit(national_reporting_user, school_move_export) }
  end

  permissions :destroy? do
    it { should_not permit(poc_only_user, school_move_export) }
    it { should_not permit(national_reporting_user, school_move_export) }
  end
end
