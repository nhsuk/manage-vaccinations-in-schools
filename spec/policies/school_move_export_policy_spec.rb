# frozen_string_literal: true

describe SchoolMoveExportPolicy do
  subject(:policy) { described_class }

  let(:point_of_care_team) { create(:team, :point_of_care) }
  let(:national_reporting_team) { create(:team, :national_reporting) }
  let(:point_of_care_user) { create(:nurse, teams: [point_of_care_team]) }
  let(:national_reporting_user) do
    create(:nurse, teams: [national_reporting_team])
  end
  let(:school_move_export) { SchoolMoveExport }

  permissions :index?, :create?, :download?, :edit?, :new?, :show?, :update? do
    it { should permit(point_of_care_user, school_move_export) }
    it { should_not permit(national_reporting_user, school_move_export) }
  end

  permissions :destroy? do
    it { should_not permit(point_of_care_user, school_move_export) }
    it { should_not permit(national_reporting_user, school_move_export) }
  end
end
