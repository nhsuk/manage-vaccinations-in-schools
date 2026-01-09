# frozen_string_literal: true

describe ConsentPolicy do
  subject(:policy) { described_class }

  let(:poc_only_team) { create(:team, :poc_only) }
  let(:upload_only_team) { create(:team, :upload_only) }
  let(:poc_only_user) { create(:nurse, teams: [poc_only_team]) }
  let(:upload_only_user) { create(:nurse, teams: [upload_only_team]) }
  let(:consent) { create(:consent) }

  permissions :index?, :create?, :edit?, :new?, :show?, :update? do
    it { should permit(poc_only_user, consent) }
    it { should_not permit(upload_only_user, consent) }
  end

  permissions :destroy? do
    it { should_not permit(poc_only_user, consent) }
    it { should_not permit(upload_only_user, consent) }
  end
end
