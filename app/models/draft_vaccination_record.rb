# frozen_string_literal: true

class DraftVaccinationRecord
  include RequestSessionPersistable
  include EditableWrapper
  include HasDoseVolume
  include VaccinationRecordPerformedByConcern
  include WizardStepConcern

  def self.request_session_key
    "vaccination_record"
  end

  attribute :batch_id, :integer
  attribute :delivery_method, :string
  attribute :delivery_site, :string
  attribute :dose_sequence, :integer
  attribute :full_dose, :boolean
  attribute :location_name, :string
  attribute :notes, :string
  attribute :outcome, :string
  attribute :patient_id, :integer
  attribute :performed_at, :datetime
  attribute :performed_by_family_name, :string
  attribute :performed_by_given_name, :string
  attribute :performed_by_user_id, :integer
  attribute :performed_ods_code, :string
  attribute :programme_id, :integer
  attribute :session_id, :integer

  validates :performed_by_family_name,
            :performed_by_given_name,
            absence: {
              if: :performed_by_user
            }

  def wizard_steps
    [
      :notes,
      :date_and_time,
      (:outcome if can_change_outcome?),
      (:delivery if administered?),
      (:batch if administered?),
      (:dose if administered? && can_be_half_dose?),
      (:location if location&.generic_clinic?),
      :confirm
    ].compact
  end

  on_wizard_step :date_and_time, exact: true do
    validates :performed_at,
              presence: true,
              comparison: {
                less_than_or_equal_to: -> { Time.current }
              }
  end

  on_wizard_step :outcome, exact: true do
    validates :outcome, inclusion: { in: VaccinationRecord.outcomes.keys }
  end

  on_wizard_step :delivery, exact: true do
    validates :delivery_site,
              inclusion: {
                in: VaccinationRecord.delivery_sites.keys
              }
    validates :delivery_method,
              inclusion: {
                in: VaccinationRecord.delivery_methods.keys
              }
  end

  on_wizard_step :batch, exact: true do
    validates :batch_id, presence: true
  end

  on_wizard_step :dose, exact: true do
    validates :full_dose, inclusion: [true, false]
  end

  on_wizard_step :location, exact: true do
    validates :location_name, presence: true
  end

  on_wizard_step :notes, exact: true do
    validates :notes, length: { maximum: 1000 }
  end

  on_wizard_step :confirm, exact: true do
    validates :outcome, presence: true
    validates :notes, length: { maximum: 1000 }
  end

  with_options on: :update,
               if: -> do
                 required_for_step?(:confirm, exact: true) && administered?
               end do
    validates :batch_id,
              :delivery_method,
              :delivery_site,
              :performed_at,
              presence: true
    validates :full_dose, inclusion: { in: [true, false] }
  end

  def administered?
    return nil if outcome.nil?
    outcome == "administered"
  end

  def already_had?
    return nil if outcome.nil?
    outcome == "already_had"
  end

  # So that a form error matches to a field in this model
  alias_method :administered, :administered?

  def batch
    return nil if batch_id.nil?

    BatchPolicy::Scope.new(@current_user, Batch).resolve.find(batch_id)
  end

  def batch=(value)
    self.batch_id = value.id
  end

  def patient
    return nil if patient_id.nil?

    Patient.find(patient_id)
  end

  def patient=(value)
    self.patient_id = value.id
  end

  delegate :location, to: :session, allow_nil: true

  def performed_by_user
    return nil if performed_by_user_id.nil?

    User.find(performed_by_user_id)
  end

  def performed_by_user=(value)
    self.performed_by_user_id = value.id
  end

  def programme
    return nil if programme_id.nil?

    ProgrammePolicy::Scope
      .new(@current_user, Programme)
      .resolve
      .find(programme_id)
  end

  def programme=(value)
    self.programme_id = value.id
  end

  def session
    return nil if session_id.nil?

    SessionPolicy::Scope.new(@current_user, Session).resolve.find(session_id)
  end

  def session=(value)
    self.session_id = value.id
  end

  def vaccination_record
    return nil if editing_id.nil?

    VaccinationRecordPolicy::Scope
      .new(@current_user, VaccinationRecord)
      .resolve
      .find(editing_id)
  end

  def vaccination_record=(value)
    self.editing_id = value.id
  end

  delegate :vaccine, to: :batch, allow_nil: true
  delegate :can_be_half_dose?, to: :vaccine, allow_nil: true

  delegate :id, to: :vaccine, prefix: true, allow_nil: true

  def vaccine_id_changed? = batch_id_changed?

  private

  def writable_attribute_names
    super + %w[vaccine_id]
  end

  def reset_unused_fields
    if administered?
      self.full_dose = true unless can_be_half_dose?
    else
      self.batch_id = nil
      self.delivery_method = nil
      self.delivery_site = nil
      self.full_dose = nil
    end
  end

  def can_change_outcome?
    outcome != "already_had" || editing? || session.nil? || session.today?
  end
end
