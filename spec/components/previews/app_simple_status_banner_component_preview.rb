# frozen_string_literal: true

class AppSimpleStatusBannerComponentPreview < ViewComponent::Preview
  def waiting_for_consent
    patient_session = FactoryBot.create(:patient_session, :added_to_session)

    render AppSimpleStatusBannerComponent.new(patient_session:)
  end

  def no_consent_and_not_gillick_competent
    patient_session =
      FactoryBot.create(:patient_session, :not_gillick_competent)

    render AppSimpleStatusBannerComponent.new(patient_session:)
  end

  def consent_refused
    patient_session = FactoryBot.create(:patient_session, :consent_refused)

    render AppSimpleStatusBannerComponent.new(patient_session:)
  end

  def consent_conflicts
    patient_session = FactoryBot.create(:patient_session, :consent_conflicting)

    render AppSimpleStatusBannerComponent.new(patient_session:)
  end

  def needs_triage
    patient_session =
      FactoryBot.create(:patient_session, :consent_given_triage_needed)

    render AppSimpleStatusBannerComponent.new(patient_session:)
  end

  def triaged_keep_in_triage
    patient_session =
      FactoryBot.create(:patient_session, :triaged_kept_in_triage)

    render AppSimpleStatusBannerComponent.new(patient_session:)
  end

  def triaged_do_not_vaccinate
    patient_session =
      FactoryBot.create(:patient_session, :triaged_do_not_vaccinate)

    render AppSimpleStatusBannerComponent.new(patient_session:)
  end

  def triaged_ready_to_vaccinate
    patient_session =
      FactoryBot.create(:patient_session, :triaged_ready_to_vaccinate)

    render AppSimpleStatusBannerComponent.new(patient_session:)
  end

  def triaged_out_delay_vaccination
    patient_session = FactoryBot.create(:patient_session, :delay_vaccination)

    render AppSimpleStatusBannerComponent.new(patient_session:)
  end
end
