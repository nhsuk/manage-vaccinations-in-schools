# frozen_string_literal: true

describe SchoolPolicy do
  subject(:policy) { described_class }

  let(:poc_only_team) { create(:team, :poc_only) }
  let(:upload_only_team) { create(:team, :upload_only) }
  let(:poc_only_user) { create(:nurse, teams: [poc_only_team]) }
  let(:upload_only_user) { create(:nurse, teams: [upload_only_team]) }
  let(:location) { create(:school) }

  permissions :index?,
              :create?,
              :import?,
              :new?,
              :patients?,
              :sessions?,
              :show? do
    it { should permit(poc_only_user, location) }
    it { should_not permit(upload_only_user, location) }
  end

  permissions :edit?, :destroy?, :update? do
    it { should_not permit(poc_only_user, location) }
    it { should_not permit(upload_only_user, location) }
  end
end
