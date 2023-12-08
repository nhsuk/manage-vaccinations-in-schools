class AppTriageFormComponent < ViewComponent::Base
  def initialize(patient_session:, triage:, url: nil)
    super

    @patient_session = patient_session
    @triage =
      triage ||
        Triage.new.tap do |t|
          if patient_session.triage.any?
            t.status = patient_session.triage.order(:created_at).last.status
          end
        end
    @url = url
  end

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def before_render
    @url ||= session_patient_triage_path(session, patient, @triage)
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

  def render?
    @patient_session.next_step == :triage
  end

  private

  def patient
    @patient_session.patient
  end

  def session
    @patient_session.session
  end

  def triage_status_options
    %i[
      ready_to_vaccinate
      do_not_vaccinate
      delay_vaccination
      needs_follow_up
    ].map { |status| [status, Triage.human_enum_name(:status, status)] }
  end
end
