# frozen_string_literal: true

describe ParentRelationshipPolicy do
  subject(:policy) { described_class }

  let(:poc_only_team) { create(:team, :poc_only) }
  let(:national_reporting_team) { create(:team, :national_reporting) }
  let(:poc_only_user) { create(:nurse, teams: [poc_only_team]) }
  let(:national_reporting_user) do
    create(:nurse, teams: [national_reporting_team])
  end
  let(:parent_relationship) { create(:parent_relationship) }

  permissions :index?,
              :confirm_destroy?,
              :create?,
              :destroy?,
              :edit?,
              :new?,
              :show?,
              :update? do
    it { should permit(poc_only_user, parent_relationship) }
    it { should_not permit(national_reporting_user, parent_relationship) }
  end
end
