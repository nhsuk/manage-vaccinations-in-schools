# frozen_string_literal: true

describe SchoolPolicy do
  subject(:policy) { described_class }

  let(:poc_only_team) { create(:team, :poc_only) }
  let(:national_reporting_team) { create(:team, :national_reporting) }
  let(:poc_only_user) { create(:nurse, teams: [poc_only_team]) }
  let(:national_reporting_user) do
    create(:nurse, teams: [national_reporting_team])
  end
  let(:location) { create(:school) }

  permissions :index?, :import?, :patients?, :sessions?, :show? do
    it { should permit(poc_only_user, location) }
    it { should_not permit(national_reporting_user, location) }
  end

  permissions :edit?, :create?, :destroy?, :new?, :update? do
    it { should_not permit(poc_only_user, location) }
    it { should_not permit(national_reporting_user, location) }
  end
end
