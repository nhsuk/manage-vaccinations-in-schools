# frozen_string_literal: true

class DraftVaccinationRecord
  include RequestSessionPersistable
  include EditableWrapper
  include WizardStepConcern

  def self.request_session_key
    "vaccination_record"
  end

  attribute :administered_at, :datetime
  attribute :batch_id, :integer
  attribute :delivery_method, :string
  attribute :delivery_site, :string
  attribute :dose_sequence, :integer
  attribute :location_name, :string
  attribute :notes, :string
  attribute :patient_session_id, :integer
  attribute :performed_by
  attribute :programme_id, :integer
  attribute :reason, :string
  attribute :vaccine_id, :integer

  def wizard_steps
    [
      (:date_and_time if administered?),
      (:delivery if administered?),
      (:vaccine if administered?),
      (:batch if administered?),
      (:location if location&.generic_clinic?),
      (:reason unless administered?),
      :confirm
    ].compact
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

  on_wizard_step :vaccine, exact: true do
    validates :vaccine_id, presence: true
  end

  on_wizard_step :batch, exact: true do
    validates :batch_id, presence: true
    validate :batch_vaccine_matches_vaccine
  end

  on_wizard_step :location, exact: true do
    validates :location_name, presence: true
  end

  on_wizard_step :reason, exact: true do
    validates :reason, inclusion: { in: VaccinationRecord.reasons.keys }
  end

  with_options on: :update do
    with_options if: -> do
                   required_for_step?(:confirm, exact: true) && administered?
                 end do
      validates :delivery_site,
                :delivery_method,
                :vaccine_id,
                :batch_id,
                presence: true
    end

    with_options if: -> do
                   required_for_step?(:confirm, exact: true) && !administered?
                 end do
      validates :reason, presence: true
    end
  end

  def administered?
    administered_at != nil
  end

  def batch
    BatchPolicy::Scope.new(@current_user, Batch).resolve.find_by(id: batch_id)
  end

  def batch=(value)
    self.batch_id = value.id
  end

  delegate :dose, to: :vaccination_record, allow_nil: true

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

  def performed_by
    @current_user
  end

  def performed_by_changed?
    false
  end

  alias_method :performed_by_family_name_changed?, :performed_by_changed?
  alias_method :performed_by_given_name_changed?, :performed_by_changed?
  alias_method :performed_by_user_id_changed?, :performed_by_changed?

  def programme
    ProgrammePolicy::Scope
      .new(@current_user, Programme)
      .resolve
      .find_by(id: programme_id)
  end

  def programme=(value)
    self.programme_id = value.id
  end

  def vaccination_record
    VaccinationRecordPolicy::Scope
      .new(@current_user, VaccinationRecord)
      .resolve
      .find_by(id: editing_id)
  end

  def vaccination_record=(value)
    self.editing_id = value.id
  end

  def vaccine
    VaccinePolicy::Scope
      .new(@current_user, Vaccine)
      .resolve
      .find_by(id: vaccine_id)
  end

  def vaccine=(value)
    self.vaccine_id = value.id
  end

  private

  def reset_unused_fields
    if administered?
      self.reason = nil
    else
      self.batch_id = nil
      self.delivery_method = nil
      self.delivery_site = nil
      self.vaccine_id = nil
    end
  end

  def batch_vaccine_matches_vaccine
    return if batch&.vaccine_id == vaccine_id

    errors.add(:batch_id, :incorrect_vaccine, vaccine_brand: vaccine&.brand)
  end
end
