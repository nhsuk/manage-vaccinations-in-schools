class AppTriageFormComponent < ViewComponent::Base
  def initialize(patient_session:, triage:, url: nil)
    super

    @patient_session = patient_session
    @triage = triage
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
    Triage.statuses.keys.map do |status|
      [status, Triage.human_enum_name(:status, status)]
    end
  end
end
