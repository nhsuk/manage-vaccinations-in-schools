# frozen_string_literal: true

describe ConsentFormPolicy do
  subject(:policy) { described_class }

  let(:poc_only_team) { create(:team, :poc_only) }
  let(:upload_only_team) { create(:team, :upload_only) }
  let(:poc_only_user) { create(:nurse, teams: [poc_only_team]) }
  let(:upload_only_user) { create(:nurse, teams: [upload_only_team]) }
  let(:consent_form) { create(:consent_form) }

  permissions :index?,
              :create?,
              :create_patient?,
              :download?,
              :edit?,
              :edit_archive?,
              :edit_match?,
              :new?,
              :new_patient?,
              :search?,
              :show?,
              :update?,
              :update_archive?,
              :update_match? do
    it { should permit(poc_only_user, consent_form) }
    it { should_not permit(upload_only_user, consent_form) }
  end

  permissions :destroy? do
    it { should_not permit(poc_only_user, consent_form) }
    it { should_not permit(upload_only_user, consent_form) }
  end
end
