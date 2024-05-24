class AppConsentComponent < ViewComponent::Base
  attr_reader :patient_session, :section, :tab

  def initialize(patient_session:, section:, tab:)
    super

    @patient_session = patient_session
    @section = section
    @tab = tab
  end

  delegate :patient, to: :patient_session
  delegate :session, to: :patient_session

  def contact_parent_or_guardian_link(consents)
    consent = consents.first
    role =
      consent.parent_relationship.in?(%w[mother father]) ? "parent" : "guardian"

    link_to(
      "Contact #{consent.parent_name} (the #{role} who refused)",
      session_patient_manage_consent_path(
        session_id: session.id,
        consent_id: consent.id,
        patient_id: patient.id,
        section: @section,
        tab: @tab,
        id: :agree
      ),
      class: "nhsuk-u-font-weight-bold"
    )
  end

  def consents
    patient_session.consents.order(recorded_at: :desc)
  end
end
