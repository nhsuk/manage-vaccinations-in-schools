# frozen_string_literal: true

describe Import::IssuePolicy do
  subject(:policy) { described_class }

  let(:poc_only_team) { create(:team, :poc_only) }
  let(:upload_only_team) { create(:team, :upload_only) }
  let(:poc_only_user) { create(:nurse, teams: [poc_only_team]) }
  let(:upload_only_user) { create(:nurse, teams: [upload_only_team]) }
  let(:vaccination_record) { create(:vaccination_record) }

  permissions :index?, :create?, :edit?, :new?, :show?, :update? do
    it { should permit(poc_only_user, vaccination_record) }
    it { should permit(upload_only_user, vaccination_record) }
  end

  permissions :destroy? do
    it { should_not permit(poc_only_user, vaccination_record) }
    it { should_not permit(upload_only_user, vaccination_record) }
  end
end
