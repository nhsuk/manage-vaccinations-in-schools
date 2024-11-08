# frozen_string_literal: true

class DraftGillickAssessment
  include RequestSessionPersistable
  include EditableWrapper
  include WizardStepConcern

  def self.request_session_key
    "gillick_assessment"
  end

  attribute :assessor
  attribute :gillick_competent, :boolean
  attribute :location_name, :string
  attribute :notes, :string
  attribute :patient_session_id, :integer

  def wizard_steps
    [
      :gillick,
      (:location if location&.generic_clinic?),
      :notes,
      :confirm
    ].compact
  end

  on_wizard_step :gillick, exact: true do
    validates :gillick_competent, inclusion: { in: [true, false] }
  end

  on_wizard_step :location, exact: true do
    validates :location_name, presence: true
  end

  on_wizard_step :notes, exact: true do
    validates :notes, length: { maximum: 1000 }, presence: true
  end

  on_wizard_step :confirm, exact: true do
    validates :gillick_competent, inclusion: { in: [true, false] }
    validates :notes, presence: true
  end

  def assessor
    @current_user
  end

  def gillick_assessment
    GillickAssessmentPolicy::Scope
      .new(@current_user, GillickAssessment)
      .resolve
      .find_by(id: editing_id)
  end

  def gillick_assessment=(value)
    self.editing_id = value.id
  end

  def patient_session
    PatientSessionPolicy::Scope
      .new(@current_user, PatientSession)
      .resolve
      .find_by(id: patient_session_id)
  end

  def patient_session=(value)
    self.patient_session_id = value.id
  end

  delegate :location, :patient, :session, to: :patient_session, allow_nil: true

  private

  def reset_unused_fields
  end
end
