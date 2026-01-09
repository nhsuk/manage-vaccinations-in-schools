# frozen_string_literal: true

describe Patient::ArchivePolicy do
  subject(:policy) { described_class }

  let(:poc_only_team) { create(:team, :poc_only) }
  let(:upload_only_team) { create(:team, :upload_only) }
  let(:poc_only_user) { create(:nurse, teams: [poc_only_team]) }
  let(:upload_only_user) { create(:nurse, teams: [upload_only_team]) }
  let(:patient) { create(:patient) }

  permissions :new?, :create? do
    it { should permit(poc_only_user, patient) }
    it { should_not permit(upload_only_user, patient) }
  end

  permissions :index?, :destroy?, :edit?, :show?, :update? do
    it { should_not permit(poc_only_user, patient) }
    it { should_not permit(upload_only_user, patient) }
  end
end
