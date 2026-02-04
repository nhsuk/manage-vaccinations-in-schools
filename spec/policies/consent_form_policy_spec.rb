# frozen_string_literal: true

describe ConsentFormPolicy do
  subject(:policy) { described_class }

  let(:point_of_care_team) { create(:team, :point_of_care) }
  let(:national_reporting_team) { create(:team, :national_reporting) }
  let(:point_of_care_user) { create(:nurse, teams: [point_of_care_team]) }
  let(:national_reporting_user) do
    create(:nurse, teams: [national_reporting_team])
  end
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
    it { should permit(point_of_care_user, consent_form) }
    it { should_not permit(national_reporting_user, consent_form) }
  end

  permissions :destroy? do
    it { should_not permit(point_of_care_user, consent_form) }
    it { should_not permit(national_reporting_user, consent_form) }
  end
end
