class TriageMailer < ApplicationMailer
  def vaccination_will_happen(patient_session)
    @patient_session = patient_session

    template_mail(
      "fa3c8dd5-4688-4b93-960a-1d422c4e5597",
      **opts(patient_session)
    )
  end

  def vaccination_wont_happen(patient_session)
    @patient_session = patient_session

    template_mail(
      "d1faf47e-ccc3-4481-975b-1ec34211a21f",
      **opts(patient_session)
    )
  end

  private

  def consent
    @patient_session.consents.order(:created_at).last
  end

  def to
    consent.parent_email
  end

  def parent_name
    consent.parent_name
  end
end
