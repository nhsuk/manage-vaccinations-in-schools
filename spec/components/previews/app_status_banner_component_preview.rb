class AppStatusBannerComponentPreview < ViewComponent::Preview
  def no_consent_and_not_gillick_competent
    patient_session =
      FactoryBot.create(:patient_session, :not_gillick_competent)

    render AppStatusBannerComponent.new(patient_session:)
  end

  def consent_conflicts
    patient_session = FactoryBot.create(:patient_session, :consent_conflicting)

    render AppStatusBannerComponent.new(patient_session:)
  end

  def triaged_out_delay_vaccination
    patient_session = FactoryBot.create(:patient_session, :delay_vaccination)

    render AppStatusBannerComponent.new(patient_session:)
  end

  def unable_to_vaccinate_with_contradications
    patient_session = FactoryBot.create(:patient_session, :unable_to_vaccinate)

    render AppStatusBannerComponent.new(patient_session:)
  end
end
