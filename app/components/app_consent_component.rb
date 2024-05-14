class AppConsentComponent < ViewComponent::Base
  attr_reader :patient_session

  def initialize(patient_session:, section:, tab:)
    super

    @patient_session = patient_session
    @section = section
    @tab = tab
  end

  delegate :patient, to: :patient_session
  delegate :session, to: :patient_session

  def display_gillick_consent_button?
    @patient_session.session.in_progress? && @patient_session.consents.empty? &&
      @patient_session.able_to_vaccinate?
  end

  def open_consents?
    !@patient_session.state.to_sym.in? %i[
                                        triaged_do_not_vaccinate
                                        unable_to_vaccinate
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

  def consents_grouped_by_parent
    @consents_grouped_by_parent ||=
      @patient_session.consents.group_by(&:summary_with_consenter)
  end

  private

  def grouped_consents(consents)
    first_consent = consents.first
    first_refused_consent = consents.find(&:response_refused?)

    props = {
      name: first_consent.name,
      response:
        consents.map do |consent|
          { text: consent.summary_with_route, timestamp: consent.recorded_at }
        end
    }
    unless first_consent.via_self_consent?
      props.merge!(
        relationship: first_consent.who_responded,
        contact: {
          phone: first_consent.parent_phone,
          email: first_consent.parent_email
        }
      )
    end

    if first_refused_consent.present?
      props[:refusal_reason] = {
        reason: first_refused_consent.human_enum_name(:reason_for_refusal),
        notes: first_refused_consent.reason_for_refusal_notes
      }
    end

    props
  end
end
