module PatientTabsConcern
  extend ActiveSupport::Concern

  TAB_STATES = {
    triage: {
      needs_triage: %w[consent_given_triage_needed triaged_kept_in_triage],
      triage_complete: %w[
        delay_vaccination
        triaged_do_not_vaccinate
        triaged_ready_to_vaccinate
      ],
      no_triage_needed: %w[
        consent_refused
        consent_given_triage_not_needed
        vaccinated
        unable_to_vaccinate
        unable_to_vaccinate_not_gillick_competent
      ]
    },
    vaccinations: {
      vaccinated: %w[vaccinated],
      could_not_vaccinate: %w[
        consent_refused
        consent_conflicts
        delay_vaccination
        triaged_do_not_vaccinate
        unable_to_vaccinate
        unable_to_vaccinate_not_gillick_competent
      ]
    }
  }.with_indifferent_access.freeze

  TAB_CONDITIONS = {
    consents: {
      consent_given: %i[consent_given?],
      consent_refused: %i[consent_refused?],
      conflicting_consent: %i[consent_conflicts?],
      no_consent: %i[no_consent?]
    }
  }.with_indifferent_access.freeze

  def group_patient_sessions_by_conditions(all_patient_sessions, section:)
    tab_conditions = TAB_CONDITIONS.fetch(section)

    all_patient_sessions
      .group_by do |patient_session| # rubocop:disable Style/BlockDelimiters
        tab_conditions
          .find { |_, conditions| conditions.any? { patient_session.send(_1) } }
          &.first
      end
      .tap { |groups| tab_conditions.each_key { groups[_1] ||= [] } }
      .except(nil)
      .with_indifferent_access
  end

  def group_patient_sessions_by_state(
    all_patient_sessions,
    tab_states = nil,
    section: nil
  )
    tab_states ||= TAB_STATES.fetch(section)

    all_patient_sessions
      .group_by do |patient_session| # rubocop:disable Style/BlockDelimiters
        tab_states.find { |_, states| patient_session.state.in? states }&.first
      end
      .tap { |groups| tab_states.each_key { groups[_1] ||= [] } }
      .except(nil)
      .with_indifferent_access
  end

  def count_patient_sessions(tab_patient_sessions)
    tab_patient_sessions.transform_values(&:count)
  end
end
