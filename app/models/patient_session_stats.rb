# frozen_string_literal: true

class PatientSessionStats
  def initialize(patient_sessions, keys: nil)
    @patient_sessions =
      patient_sessions.sort_by(&:created_at).reverse.uniq(&:patient_id)
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
        ]
  end

  delegate :[], to: :statistics

  def to_h
    statistics
  end

  private

  def statistics
    @statistics ||=
      @keys.index_with do |key|
        @patient_sessions.count { include_in_statistics?(_1, key) }
      end
  end

  def include_in_statistics?(patient_session, key)
    case key
    when :with_consent_given
      patient_session.consent_given?
    when :with_consent_refused
      patient_session.consent_refused?
    when :with_conflicting_consent
      patient_session.consent_conflicts?
    when :without_a_response
      patient_session.no_consent?
    when :needing_triage
      patient_session.consent_given_triage_needed? ||
        patient_session.triaged_kept_in_triage?
    when :vaccinate
      patient_session.triaged_ready_to_vaccinate? ||
        patient_session.consent_given_triage_not_needed?
    when :vaccinated
      patient_session.vaccinated?
    when :could_not_vaccinate
      patient_session.delay_vaccination? || patient_session.consent_refused? ||
        patient_session.consent_conflicts? ||
        patient_session.triaged_do_not_vaccinate? ||
        patient_session.unable_to_vaccinate? ||
        patient_session.unable_to_vaccinate_not_gillick_competent?
    end
  end
end
