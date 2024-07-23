# frozen_string_literal: true

class AppOutcomeBannerComponentPreview < ViewComponent::Preview
  include FactoryBot::Syntax::Methods

  def triaged_do_not_vaccinate
    patient_session = create(:patient_session, :triaged_do_not_vaccinate)

    render AppOutcomeBannerComponent.new(patient_session:)
  end

  def unable_to_vaccinate_with_contradications
    patient_session = create(:patient_session, :unable_to_vaccinate)

    render AppOutcomeBannerComponent.new(patient_session:)
  end

  def vaccinated
    patient_session = create(:patient_session, :vaccinated)
    patient_session.vaccination_records.first.update!(
      notes: "Patient felt dizzy"
    )

    render AppOutcomeBannerComponent.new(patient_session:)
  end
end
