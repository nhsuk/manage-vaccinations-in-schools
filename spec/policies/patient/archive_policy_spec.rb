# frozen_string_literal: true

describe Patient::ArchivePolicy do
  subject(:policy) { described_class }

  let(:point_of_care_team) { create(:team, :point_of_care) }
  let(:national_reporting_team) { create(:team, :national_reporting) }
  let(:point_of_care_user) { create(:nurse, teams: [point_of_care_team]) }
  let(:national_reporting_user) do
    create(:nurse, teams: [national_reporting_team])
  end
  let(:patient) { create(:patient) }

  permissions :new?, :create? do
    it { should permit(point_of_care_user, patient) }
    it { should_not permit(national_reporting_user, patient) }
  end

  permissions :index?, :destroy?, :edit?, :show?, :update? do
    it { should_not permit(point_of_care_user, patient) }
    it { should_not permit(national_reporting_user, patient) }
  end
end
