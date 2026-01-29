# frozen_string_literal: true

describe TeamPolicy do
  subject(:policy) { described_class }

  let(:point_of_care_team) { create(:team, :point_of_care) }
  let(:national_reporting_team) { create(:team, :national_reporting) }
  let(:other_team) { create(:team) }
  let(:user) do
    create(:nurse, teams: [point_of_care_team, national_reporting_team])
  end

  permissions :index?, :create?, :destroy?, :update? do
    it { should_not permit(user, point_of_care_team) }
    it { should_not permit(user, national_reporting_team) }
  end

  permissions :show?, :clinics?, :contact_details?, :schools?, :sessions? do
    it { should permit(user, point_of_care_team) }
    it { should_not permit(user, national_reporting_team) }
    it { should_not permit(user, other_team) }
  end
end
