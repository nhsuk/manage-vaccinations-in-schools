class AppVaccinateFormComponent < ViewComponent::Base
  def initialize(patient_session:, vaccination_record:, url: nil)
    super

    @patient_session = patient_session
    @url = url
    @vaccination_record = vaccination_record
  end

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def before_render
    @url ||=
      session_patient_vaccinations_path(
        session_id: session.id,
        patient_id: patient.id
      )
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

  def render?
    @patient_session.next_step == :vaccinate && session.in_progress?
  end

  private

  def patient
    @patient_session.patient
  end

  def session
    @patient_session.session
  end

  def campaign_name
    @patient_session.campaign.name
  end

  def vaccination_initial_delivery_sites
    %w[left_arm right_arm other]
  end
end
