# frozen_string_literal: true

class PatientSessionStats
  def initialize(patient_sessions, programme:, keys: nil)
    @patient_sessions =
      patient_sessions.sort_by(&:created_at).reverse.uniq(&:patient_id)
    @programme = programme
    @keys =
      keys ||
        %i[
          with_consent_given
          with_consent_refused
          without_a_response
          needing_triage
          vaccinate
          vaccinated
          could_not_vaccinate
          with_conflicting_consent
          not_registered
        ]
  end

  delegate :[], to: :statistics

  def to_h
    statistics
  end

  private

  attr_reader :programme

  def statistics
    @statistics ||=
      @keys.index_with do |key|
        @patient_sessions.count { include_in_statistics?(_1, key) }
      end
  end

  def include_in_statistics?(patient_session, key)
    case key
    when :with_consent_given
      patient_session.consent_given?(programme:)
    when :with_consent_refused
      patient_session.consent_refused?(programme:)
    when :with_conflicting_consent
      patient_session.consent_conflicts?(programme:)
    when :without_a_response
      patient_session.no_consent?(programme:)
    when :needing_triage
      patient_session.consent_given_triage_needed?(programme:) ||
        patient_session.triaged_kept_in_triage?(programme:)
    when :vaccinate
      patient_session.triaged_ready_to_vaccinate?(programme:) ||
        patient_session.consent_given_triage_not_needed?(programme:)
    when :vaccinated
      patient_session.vaccinated?(programme:)
    when :could_not_vaccinate
      patient_session.delay_vaccination?(programme:) ||
        patient_session.consent_refused?(programme:) ||
        patient_session.consent_conflicts?(programme:) ||
        patient_session.triaged_do_not_vaccinate?(programme:) ||
        patient_session.unable_to_vaccinate?(programme:)
    when :not_registered
      patient_session.todays_attendance&.attending.nil?
    end
  end
end
