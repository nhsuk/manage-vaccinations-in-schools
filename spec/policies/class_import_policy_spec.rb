# frozen_string_literal: true

describe ClassImportPolicy do
  subject(:policy) { described_class }

  let(:point_of_care_team) { create(:team, :point_of_care) }
  let(:national_reporting_team) { create(:team, :national_reporting) }
  let(:point_of_care_user) { create(:nurse, teams: [point_of_care_team]) }
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
    it { should permit(point_of_care_user, class_import) }
    it { should_not permit(national_reporting_user, class_import) }
  end

  permissions :destroy? do
    it { should_not permit(point_of_care_user, class_import) }
    it { should_not permit(national_reporting_user, class_import) }
  end
end
