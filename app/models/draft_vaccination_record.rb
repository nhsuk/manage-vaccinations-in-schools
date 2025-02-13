# frozen_string_literal: true

class DraftVaccinationRecord
  include RequestSessionPersistable
  include EditableWrapper
  include VaccinationRecordPerformedByConcern
  include WizardStepConcern

  def self.request_session_key
    "vaccination_record"
  end

  attribute :batch_id, :integer
  attribute :delivery_method, :string
  attribute :delivery_site, :string
  attribute :dose_sequence, :integer
  attribute :location_name, :string
  attribute :notes, :string
  attribute :outcome, :string
  attribute :patient_id, :integer
  attribute :session_id, :integer
  attribute :performed_at, :datetime
  attribute :performed_by_family_name, :string
  attribute :performed_by_given_name, :string
  attribute :performed_by_user_id, :integer
  attribute :performed_ods_code, :string
  attribute :programme_id, :integer
  attribute :vaccine_id, :integer

  validates :performed_by_family_name,
            :performed_by_given_name,
            absence: {
              if: :performed_by_user
            }

  def wizard_steps
    [
      :notes,
      :date_and_time,
      :outcome,
      (:delivery if administered?),
      (:vaccine if administered?),
      (:batch if administered?),
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

  on_wizard_step :confirm, exact: true do
    validates :outcome, presence: true
  end

  with_options on: :update,
               if: -> do
                 required_for_step?(:confirm, exact: true) && administered?
               end do
    validates :batch_id,
              :delivery_method,
              :delivery_site,
              :performed_at,
              :vaccine_id,
              presence: true
  end

  def administered?
    return nil if outcome.nil?
    outcome == "administered"
  end

  # So that a form error matches to a field in this model
  alias_method :administered, :administered?

  def batch
    BatchPolicy::Scope.new(@current_user, Batch).resolve.find_by(id: batch_id)
  end

  def batch=(value)
    self.batch_id = value.id
  end

  def dose_volume_ml
    # TODO: this will need to be revisited once it's possible to record half-doses
    # e.g. for the flu programme where a child refuses the second half of the dose
    vaccine.dose_volume_ml * 1 if vaccine.present?
  end

  def patient
    Patient.find_by(id: patient_id)
  end

  def patient=(value)
    self.patient_id = value.id
  end

  delegate :location, to: :session, allow_nil: true

  def performed_by_user
    User.find_by(id: performed_by_user_id)
  end

  def performed_by_user=(value)
    self.performed_by_user_id = value.id
  end

  def programme
    ProgrammePolicy::Scope
      .new(@current_user, Programme)
      .resolve
      .find_by(id: programme_id)
  end

  def programme=(value)
    self.programme_id = value.id
  end

  def session
    SessionPolicy::Scope
      .new(@current_user, Session)
      .resolve
      .find_by(id: session_id)
  end

  def session=(value)
    self.session_id = value.id
  end

  def vaccination_record
    VaccinationRecordPolicy::Scope
      .new(@current_user, VaccinationRecord)
      .resolve
      .includes(patient: { consents: :parent })
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

  def writable_attribute_names
    super - %w[vaccine_id]
  end

  def reset_unused_fields
    if administered?
      if vaccine_id.nil? && programme &&
           (vaccines = programme.vaccines.active).count == 1
        self.vaccine_id = vaccines.first.id
      end
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
