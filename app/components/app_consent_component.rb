class AppConsentComponent < ViewComponent::Base
  attr_reader :patient_session

  def initialize(patient_session:, route:)
    super

    @patient_session = patient_session
    @route = route
  end

  delegate :patient, to: :patient_session
  delegate :session, to: :patient_session

  def display_health_questions?
    @patient_session.consents.any?(&:response_given?)
  end

  def open_health_questions?
    @patient_session.consents.any?(&:health_answers_require_follow_up?) &&
      @patient_session.vaccination_records.administered.none?
  end

  def display_gillick_consent_button?
    @patient_session.session.in_progress? && @patient_session.consents.empty? &&
      @patient_session.able_to_vaccinate?
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

  def contact_parent_or_guardian_link(consents)
    consent = consents.first
    role =
      consent.parent_relationship.in?(%w[mother father]) ? "parent" : "guardian"

    link_to(
      "Contact #{consent.parent_name} (the #{role} who refused)",
      session_patient_manage_consent_path(
        session,
        patient,
        @route,
        consent.id,
        :agree
      ),
      class: "nhsuk-u-font-weight-bold"
    )
  end

  def consents_grouped_by_parent
    @consents_grouped_by_parent ||=
      @patient_session.consents.group_by(&:summary_with_consenter)
  end
end
