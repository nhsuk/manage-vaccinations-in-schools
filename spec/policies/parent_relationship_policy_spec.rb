# frozen_string_literal: true

describe ParentRelationshipPolicy do
  subject(:policy) { described_class }

  let(:poc_only_team) { create(:team, :poc_only) }
  let(:upload_only_team) { create(:team, :upload_only) }
  let(:poc_only_user) { create(:nurse, teams: [poc_only_team]) }
  let(:upload_only_user) { create(:nurse, teams: [upload_only_team]) }
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
    it { should_not permit(upload_only_user, parent_relationship) }
  end
end
