class AppConsentComponent < ViewComponent::Base
  attr_reader :patient_session, :consent

  def initialize(patient_session:, consent:, route:)
    super

    @patient_session = patient_session
    @consent = consent
    @route = route
  end

  delegate :patient, to: :patient_session
  delegate :session, to: :patient_session

  def display_health_questions?
    @consent&.response_given?
  end

  def open_health_questions?
    @patient_session.consent_given_triage_needed?
  end

  def display_gillick_consent_button?
    @consent.nil? && @patient_session.able_to_vaccinate?
  end

  def open_consents?
    !@patient_session.state.to_sym.in? %i[
                                        triaged_do_not_vaccinate
                                        unable_to_vaccinate
                                        unable_to_vaccinate_not_assessed
                                        unable_to_vaccinate_not_gillick_competent
                                        vaccinated
                                      ]
  end

  def contact_parent_or_guardian_link
    link_to(
      "Contact parent or guardian",
      new_session_patient_nurse_consents_path(session, patient, @route),
      class: "nhsuk-u-font-weight-bold"
    )
  end

  def consents_grouped_by_parent
    @consents_grouped_by_parent ||=
      @patient_session.consents.group_by do |consent|
        relationship = consent.human_enum_name(:parent_relationship).capitalize
        response = consent.human_enum_name(:response).capitalize
        "#{response} by #{consent.parent_name} (#{relationship})"
      end
  end
end
