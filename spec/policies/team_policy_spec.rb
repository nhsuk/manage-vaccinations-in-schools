# frozen_string_literal: true

describe TeamPolicy do
  subject(:policy) { described_class }

  let(:poc_only_team) { create(:team, :poc_only) }
  let(:upload_only_team) { create(:team, :upload_only) }
  let(:user) { create(:nurse, teams: [poc_only_team, upload_only_team]) }

  permissions :index?, :create?, :destroy?, :update? do
    it { should_not permit(user, poc_only_team) }
    it { should_not permit(user, upload_only_team) }
  end

  permissions :show? do
    it { should permit(user, poc_only_team) }
    it { should_not permit(user, upload_only_team) }
    it { should_not permit(user, create(:team)) }
  end
end
