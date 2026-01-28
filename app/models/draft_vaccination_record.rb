# frozen_string_literal: true

class DraftVaccinationRecord
  include RequestSessionPersistable
  include EditableWrapper
  include WizardStepConcern

  include HasDoseVolume
  include PerformableAtDateAndTime
  include PerformableBy
  include Programmable

  attribute :batch_id, :integer
  attribute :batch_name, :string
  attribute :batch_expiry, :date
  attribute :delivery_method, :string
  attribute :delivery_site, :string
  attribute :disease_types, array: true
  attribute :dose_sequence, :integer
  attribute :first_active_wizard_step, :string
  attribute :full_dose, :boolean
  attribute :identity_check_confirmed_by_other_name, :string
  attribute :identity_check_confirmed_by_other_relationship, :string
  attribute :identity_check_confirmed_by_patient, :boolean
  attribute :location_id, :integer
  attribute :location_name, :string
  attribute :notes, :string
  attribute :outcome, :string
  attribute :patient_id, :integer
  attribute :performed_at_date, :date
  attribute :performed_at_time, :time
  attribute :performed_by_family_name, :string
  attribute :performed_by_given_name, :string
  attribute :performed_by_user_id, :integer
  attribute :performed_ods_code, :string
  attribute :programme_type, :string
  attribute :protocol, :string
  attribute :session_id, :integer
  attribute :source, :string
  attribute :supplied_by_user_id, :integer
  attribute :vaccine_id, :integer

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
      (:supplier if requires_supplied_by?),
      (:delivery if administered?),
      (:dose if administered? && can_be_half_dose?),
      (:batch if administered?),
      (:location if session&.generic_clinic? || bulk_upload_user_and_record?),
      (:dose_sequence if bulk_upload_user_and_record?),
      (:vaccinator if bulk_upload_user_and_record?),
      :confirm
    ].compact
  end

  on_wizard_step :date_and_time, exact: true do
    validates :performed_at_date, :performed_at_time, presence: true
    validate :performed_at_date_within_range
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
    validates :batch_id, presence: true, unless: :bulk_upload_user_and_record?

    validates :vaccine_id, presence: true, if: :bulk_upload_user_and_record?
    validates :batch_name, batch_name: true, if: :bulk_upload_user_and_record?
    validates :batch_expiry, presence: true, if: :bulk_upload_user_and_record?
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
    validate :location_is_school, if: :bulk_upload_user_and_record?
    validates :location_id,
              presence: true,
              unless: :bulk_upload_user_and_record?
  end

  on_wizard_step :notes, exact: true do
    validates :notes, length: { maximum: 1000 }
  end

  on_wizard_step :confirm, exact: true do
    validates :outcome, presence: true
    validates :notes, length: { maximum: 1000 }
  end

  on_wizard_step :vaccinator, exact: true do
    validates :performed_by_given_name, presence: true
    validates :performed_by_family_name, presence: true
  end

  on_wizard_step :dose_sequence, exact: true do
    validates :dose_sequence,
              presence: true,
              inclusion: {
                in: ->(record) { 1..record.programme.maximum_dose_sequence }
              }
  end

  with_options on: :update,
               if: -> do
                 required_for_step?(:confirm, exact: true) && administered?
               end do
    validates :batch_id,
              :delivery_method,
              :delivery_site,
              :performed_at_date,
              :performed_at_time,
              :protocol,
              presence: true
    validates :full_dose, inclusion: { in: [true, false] }
    validates :source, inclusion: { in: VaccinationRecord.sources.keys }
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
    if batch_expiry && batch_name && vaccine_id && bulk_upload_user_and_record?
      return(
        Batch.create_with(archived_at: Time.current).find_or_create_by!(
          expiry: batch_expiry,
          name: batch_name,
          team_id: nil,
          vaccine_id: vaccine_id
        )
      )
    end

    return nil if batch_id.nil?
    Batch.find(batch_id)
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

  def session
    return nil if session_id.nil?

    SessionPolicy::Scope.new(@current_user, Session).resolve.find(session_id)
  end

  def session=(value)
    self.session_id = value.id
  end

  def supplied_by
    return nil if supplied_by_user_id.nil?

    User.find(supplied_by_user_id)
  end

  def supplied_by=(value)
    self.supplied_by_user_id = value.id
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

  def vaccine_id_changed? = batch_id_changed?

  def location_is_school
    return if location_id.blank?

    unless location&.school?
      errors.add(:location_id, "The location must be a school")
    end
  end

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
    if delivery_method.blank? || !administered? || academic_year.nil?
      return true
    end

    # We can't use `patient.vaccine_criteria` because once vaccinated a
    # patient no longer has an approved list of vaccine methods (they don't
    # need the vaccine).

    consent_generator =
      StatusGenerator::Consent.new(
        programme_type:,
        academic_year:,
        patient:,
        consents: patient.consents,
        vaccination_records: []
      )

    triage_generator =
      StatusGenerator::Triage.new(
        programme_type:,
        academic_year:,
        patient:,
        consents: patient.consents,
        triages: patient.triages,
        vaccination_records: []
      )

    approved_vaccine_methods =
      if triage_generator.status.in?(%i[not_required delay_vaccination])
        consent_generator.vaccine_methods
      else
        [triage_generator.vaccine_method].compact
      end

    vaccine_method = Vaccine.delivery_method_to_vaccine_method(delivery_method)

    approved_vaccine_methods.include?(vaccine_method)
  end

  def human_enum_name(attribute)
    VaccinationRecord.human_enum_name(attribute, send(attribute))
  end

  def sourced_from_service? = source == "service"

  def sourced_from_historical_upload? = source == "historical_upload"

  def sourced_from_nhs_immunisations_api? = source == "nhs_immunisations_api"

  def sourced_from_consent_refusal? = source == "consent_refusal"

  def sourced_from_bulk_upload? = source == "bulk_upload"

  def bulk_upload_user_and_record?
    @current_user.selected_team.has_upload_only_access? &&
      sourced_from_bulk_upload?
  end

  def read_from!(vaccination_record)
    self.batch_name = vaccination_record.batch&.name
    self.batch_expiry = vaccination_record.batch&.expiry
    self.vaccine_id = vaccination_record.vaccine&.id

    super(vaccination_record)
  end

  def write_to!(vaccination_record)
    super(vaccination_record)

    if batch_expiry && batch_name && vaccine_id && bulk_upload_user_and_record?
      vaccination_record.batch_id = batch&.id
    end

    vaccination_record.vaccine_id = batch&.vaccine_id
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
      disease_types
      dose_sequence
      full_dose
      identity_check
      location_id
      location_name
      notes
      outcome
      patient_id
      performed_at_date
      performed_at_time
      performed_by_family_name
      performed_by_given_name
      performed_by_user_id
      performed_ods_code
      programme_type
      protocol
      session_id
      source
      supplied_by_user_id
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

  def academic_year = session&.academic_year

  def earliest_possible_date
    academic_year.to_academic_year_date_range.first
  end

  def latest_possible_date
    [academic_year.to_academic_year_date_range.last, Date.current].min
  end

  def performed_at_date_within_range
    return if performed_at_date.nil? || session.nil?

    if performed_at_date < earliest_possible_date
      errors.add(
        :performed_at_date,
        "The vaccination cannot take place before #{earliest_possible_date.to_fs(:long)}"
      )
    elsif performed_at_date > latest_possible_date
      errors.add(
        :performed_at_date,
        "The vaccination cannot take place after #{latest_possible_date.to_fs(:long)}"
      )
    end
  end

  def vaccine_method
    Vaccine.delivery_method_to_vaccine_method(delivery_method)
  end

  def can_be_half_dose? = vaccine_method == "nasal"

  def can_change_outcome?
    (outcome != "already_had" || editing? || session.nil? || session.today?) &&
      !bulk_upload_user_and_record?
  end

  def requires_supplied_by?
    performed_by_user && !performed_by_user&.show_in_suppliers
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
