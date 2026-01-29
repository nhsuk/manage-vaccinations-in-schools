# frozen_string_literal: true

describe TeamPolicy do
  subject(:policy) { described_class }

  let(:poc_only_team) { create(:team, :poc_only) }
  let(:national_reporting_team) { create(:team, :national_reporting) }
  let(:other_team) { create(:team) }
  let(:user) { create(:nurse, teams: [poc_only_team, national_reporting_team]) }

  permissions :index?, :create?, :destroy?, :update? do
    it { should_not permit(user, poc_only_team) }
    it { should_not permit(user, national_reporting_team) }
  end

  permissions :show?, :clinics?, :contact_details?, :schools?, :sessions? do
    it { should permit(user, poc_only_team) }
    it { should_not permit(user, national_reporting_team) }
    it { should_not permit(user, other_team) }
  end
end
