# frozen_string_literal: true

class DraftVaccinationRecord
  include RequestSessionPersistable
  include EditableWrapper
  include HasDoseVolume
  include VaccinationRecordPerformedByConcern
  include WizardStepConcern

  attribute :batch_id, :integer
  attribute :delivery_method, :string
  attribute :delivery_site, :string
  attribute :dose_sequence, :integer
  attribute :full_dose, :boolean
  attribute :protocol, :string
  attribute :identity_check_confirmed_by_other_name, :string
  attribute :identity_check_confirmed_by_other_relationship, :string
  attribute :identity_check_confirmed_by_patient, :boolean
  attribute :location_id, :integer
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
  attribute :first_active_wizard_step, :string

  def initialize(current_user:, **attributes)
    @current_user = current_user
    super(**attributes)
  end

  validates :performed_by_family_name,
            :performed_by_given_name,
            absence: {
              if: :performed_by_user
            }

  def wizard_steps
    [
      :identity,
      :notes,
      :date_and_time,
      (:outcome if can_change_outcome?),
      (:delivery if administered?),
      (:dose if administered? && can_be_half_dose?),
      (:batch if administered?),
      (:location if session&.generic_clinic?),
      :confirm
    ].compact
  end

  on_wizard_step :date_and_time, exact: true do
    validates :performed_at, presence: true
    validate :performed_at_within_range
  end

  on_wizard_step :outcome, exact: true do
    validates :outcome, inclusion: { in: VaccinationRecord.outcomes.keys }
  end

  on_wizard_step :delivery, exact: true do
    validates :delivery_method,
              inclusion: {
                in: VaccinationRecord.delivery_methods.keys
              }
    validate :delivery_site_matches_delivery_method
  end

  on_wizard_step :batch, exact: true do
    validates :batch_id, presence: true
  end

  on_wizard_step :dose, exact: true do
    validates :full_dose, inclusion: [true, false]
  end

  on_wizard_step :identity, exact: true do
    validates :identity_check_confirmed_by_patient, inclusion: [true, false]
    validates :identity_check_confirmed_by_other_name,
              :identity_check_confirmed_by_other_relationship,
              presence: {
                if: -> { identity_check_confirmed_by_patient == false }
              }
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
              :protocol,
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

  def protocol
    :pgd
  end

  def batch
    return nil if batch_id.nil?

    BatchPolicy::Scope.new(@current_user, Batch).resolve.find(batch_id)
  end

  def batch=(value)
    self.batch_id = value.id
  end

  def location
    return nil if location_id.nil?
    Location.find(location_id)
  end

  def location=(value)
    self.location_id = value&.id
  end

  def patient
    return nil if patient_id.nil?

    Patient.find(patient_id)
  end

  def patient=(value)
    self.patient_id = value.id
  end

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

    SessionPolicy::Scope
      .new(@current_user, Session)
      .resolve
      .includes(:programmes)
      .find(session_id)
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

  def delivery_method=(value)
    super
    return if delivery_method_was.nil? # Don't clear batch on first set

    previous_value =
      Vaccine.delivery_method_to_vaccine_method(delivery_method_was)
    new_value = Vaccine.delivery_method_to_vaccine_method(value)

    self.batch_id = nil unless previous_value == new_value
  end

  delegate :vaccine, to: :batch, allow_nil: true

  delegate :id, to: :vaccine, prefix: true, allow_nil: true

  def vaccine_id_changed? = batch_id_changed?

  def identity_check
    return nil if identity_check_confirmed_by_patient.nil?

    (
      vaccination_record&.identity_check || IdentityCheck.new
    ).tap do |identity_check|
      identity_check.assign_attributes(
        confirmed_by_patient: identity_check_confirmed_by_patient,
        confirmed_by_other_name: identity_check_confirmed_by_other_name,
        confirmed_by_other_relationship:
          identity_check_confirmed_by_other_relationship
      )
    end
  end

  def identity_check=(identity_check)
    self.identity_check_confirmed_by_patient =
      identity_check&.confirmed_by_patient
    self.identity_check_confirmed_by_other_name =
      identity_check&.confirmed_by_other_name
    self.identity_check_confirmed_by_other_relationship =
      identity_check&.confirmed_by_other_relationship
  end

  def vaccine_method_matches_consent_and_triage?
    return true if delivery_method.blank? || !administered?

    academic_year = session&.academic_year || performed_at.academic_year
    approved_methods =
      patient.approved_vaccine_methods(programme:, academic_year:)
    vaccine_method = Vaccine.delivery_method_to_vaccine_method(delivery_method)

    approved_methods.include?(vaccine_method)
  end

  private

  def readable_attribute_names
    writable_attribute_names - %w[vaccine_id]
  end

  def writable_attribute_names
    %w[
      batch_id
      delivery_method
      delivery_site
      dose_sequence
      full_dose
      protocol
      identity_check
      location_id
      location_name
      notes
      outcome
      patient_id
      performed_at
      performed_by_family_name
      performed_by_given_name
      performed_by_user_id
      performed_ods_code
      programme_id
      session_id
      vaccine_id
    ]
  end

  def request_session_key = "vaccination_record"

  def reset_unused_attributes
    if administered?
      self.full_dose = true unless can_be_half_dose?
    else
      self.batch_id = nil
      self.delivery_method = nil
      self.delivery_site = nil
      self.full_dose = nil
    end

    if identity_check_confirmed_by_patient
      self.identity_check_confirmed_by_other_name = ""
      self.identity_check_confirmed_by_other_relationship = ""
    end
  end

  def earliest_possible_value
    session.academic_year.to_academic_year_date_range.first.beginning_of_day
  end

  def latest_possible_value
    [
      session.academic_year.to_academic_year_date_range.last.end_of_day,
      Time.current
    ].min
  end

  def performed_at_within_range
    return if performed_at.nil? || session.nil?
    if performed_at < earliest_possible_value
      errors.add(
        :performed_at,
        "The vaccination cannot take place before #{earliest_possible_value.to_fs(:long)}"
      )
    elsif performed_at > latest_possible_value
      errors.add(
        :performed_at,
        "The vaccination cannot take place after #{latest_possible_value.to_fs(:long)}"
      )
    end
  end

  def vaccine_method
    Vaccine.delivery_method_to_vaccine_method(delivery_method)
  end

  def can_be_half_dose? = vaccine_method == "nasal"

  def can_change_outcome?
    outcome != "already_had" || editing? || session.nil? || session.today?
  end

  def delivery_site_matches_delivery_method
    return if delivery_method.blank?

    if delivery_site.blank?
      errors.add(:delivery_site, :blank)
      return
    end

    allowed_delivery_sites =
      Vaccine::AVAILABLE_DELIVERY_SITES.fetch(vaccine_method)

    unless delivery_site.in?(allowed_delivery_sites)
      if vaccine_method == "injection"
        errors.add(:delivery_site, :injection_cannot_be_nose)
      else
        errors.add(:delivery_site, :nasal_spray_must_be_nose)
      end
    end

    unless VaccinationRecord.delivery_sites.keys.include?(delivery_site)
      errors.add(:delivery_site, :inclusion)
    end
  end
end
