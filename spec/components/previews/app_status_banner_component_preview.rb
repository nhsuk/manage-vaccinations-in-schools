class AppStatusBannerComponentPreview < ViewComponent::Preview
  def unable_to_vaccinate_with_contradications
    patient_session = FactoryBot.create(:patient_session, :unable_to_vaccinate)

    render AppStatusBannerComponent.new(patient_session:)
  end
end
