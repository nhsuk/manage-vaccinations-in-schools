# frozen_string_literal: true

describe ClassImportPolicy do
  subject(:policy) { described_class }

  let(:poc_only_team) { create(:team, :poc_only) }
  let(:upload_only_team) { create(:team, :upload_only) }
  let(:poc_only_user) { create(:nurse, teams: [poc_only_team]) }
  let(:upload_only_user) { create(:nurse, teams: [upload_only_team]) }
  let(:class_import) { create(:class_import) }

  permissions :index?,
              :approve?,
              :cancel?,
              :create?,
              :edit?,
              :new?,
              :re_review?,
              :show?,
              :update? do
    it { should permit(poc_only_user, class_import) }
    it { should_not permit(upload_only_user, class_import) }
  end

  permissions :destroy? do
    it { should_not permit(poc_only_user, class_import) }
    it { should_not permit(upload_only_user, class_import) }
  end
end
