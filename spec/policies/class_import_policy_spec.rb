# frozen_string_literal: true

describe ClassImportPolicy do
  subject(:policy) { described_class }

  let(:poc_only_team) { create(:team, :poc_only) }
  let(:national_reporting_team) { create(:team, :national_reporting) }
  let(:poc_only_user) { create(:nurse, teams: [poc_only_team]) }
  let(:national_reporting_user) do
    create(:nurse, teams: [national_reporting_team])
  end
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
    it { should_not permit(national_reporting_user, class_import) }
  end

  permissions :destroy? do
    it { should_not permit(poc_only_user, class_import) }
    it { should_not permit(national_reporting_user, class_import) }
  end
end
