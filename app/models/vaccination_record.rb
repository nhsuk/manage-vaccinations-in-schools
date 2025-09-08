# frozen_string_literal: true

# == Schema Information
#
# Table name: vaccination_records
#
#  id                                    :bigint           not null, primary key
#  batch_expiry                          :date
#  batch_name                            :string
#  confirmation_sent_at                  :datetime
#  delivery_method                       :integer
#  delivery_site                         :integer
#  discarded_at                          :datetime
#  dose_sequence                         :integer
#  full_dose                             :boolean
#  location_name                         :string
#  nhs_immunisations_api_etag            :string
#  nhs_immunisations_api_sync_pending_at :datetime
#  nhs_immunisations_api_synced_at       :datetime
#  notes                                 :text
#  notify_parents                        :boolean
#  outcome                               :integer          not null
#  pending_changes                       :jsonb            not null
#  performed_at                          :datetime         not null
#  performed_by_family_name              :string
#  performed_by_given_name               :string
#  performed_ods_code                    :string
#  protocol                              :integer
#  source                                :integer          not null
#  uuid                                  :uuid             not null
#  created_at                            :datetime         not null
#  updated_at                            :datetime         not null
#  batch_id                              :bigint
#  location_id                           :bigint
#  nhs_immunisations_api_id              :string
#  patient_id                            :bigint           not null
#  performed_by_user_id                  :bigint
#  programme_id                          :bigint           not null
#  session_id                            :bigint
#  supplied_by_user_id                   :bigint
#  vaccine_id                            :bigint
#
# Indexes
#
#  index_vaccination_records_on_batch_id                  (batch_id)
#  index_vaccination_records_on_discarded_at              (discarded_at)
#  index_vaccination_records_on_location_id               (location_id)
#  index_vaccination_records_on_nhs_immunisations_api_id  (nhs_immunisations_api_id) UNIQUE
#  index_vaccination_records_on_patient_id                (patient_id)
#  index_vaccination_records_on_performed_by_user_id      (performed_by_user_id)
#  index_vaccination_records_on_programme_id              (programme_id)
#  index_vaccination_records_on_session_id                (session_id)
#  index_vaccination_records_on_supplied_by_user_id       (supplied_by_user_id)
#  index_vaccination_records_on_uuid                      (uuid) UNIQUE
#  index_vaccination_records_on_vaccine_id                (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (batch_id => batches.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (session_id => sessions.id)
#  fk_rails_...  (supplied_by_user_id => users.id)
#  fk_rails_...  (vaccine_id => vaccines.id)
#
class VaccinationRecord < ApplicationRecord
  include Discard::Model
  include HasDoseVolume
  include PendingChangesConcern
  include VaccinationRecordPerformedByConcern
  include VaccinationRecordSyncToNHSImmunisationsAPIConcern

  audited associated_with: :patient

  DELIVERY_SITE_SNOMED_CODES_AND_TERMS = {
    left_thigh: ["61396006", "Structure of left thigh"],
    right_thigh: ["11207009", "Structure of right thigh"],
    left_arm_upper_position: ["368208006", "Left upper arm structure"],
    left_arm_lower_position: ["368208006", "Left upper arm structure"],
    right_arm_upper_position: ["368209003", "Right upper arm structure"],
    right_arm_lower_position: ["368209003", "Right upper arm structure"],
    left_buttock: ["723979003", "Structure of left buttock"],
    right_buttock: ["723980000", "Structure of right buttock"],
    nose: ["279549004", "Nasal cavity structure"]
  }.with_indifferent_access

  DELIVERY_METHOD_SNOMED_CODES_AND_TERMS = {
    intramuscular: %w[78421000 Intramuscular],
    subcutaneous: %w[34206005 Subcutaneous],
    nasal_spray: %w[46713006 Nasal]
  }.with_indifferent_access

  belongs_to :batch, optional: true
  belongs_to :vaccine, optional: true
  belongs_to :programme

  belongs_to :performed_by_user, class_name: "User", optional: true
  belongs_to :supplied_by,
             class_name: "User",
             foreign_key: :supplied_by_user_id,
             optional: true

  has_and_belongs_to_many :immunisation_imports

  belongs_to :location, optional: true
  belongs_to :patient
  belongs_to :session, optional: true

  has_one :identity_check, autosave: true, dependent: :destroy
  has_one :organisation, through: :session
  has_one :subteam, through: :session
  has_one :team, through: :session

  scope :for_academic_year,
        ->(academic_year) do
          where(performed_at: academic_year.to_academic_year_date_range)
        end

  scope :recorded_in_service, -> { where.not(session_id: nil) }

  enum :protocol, { pgd: 0, psd: 1, national: 2 }, validate: { allow_nil: true }

  enum :delivery_method,
       { intramuscular: 0, subcutaneous: 1, nasal_spray: 2 },
       prefix: true

  enum :delivery_site,
       {
         left_arm_upper_position: 2,
         left_arm_lower_position: 3,
         right_arm_upper_position: 4,
         right_arm_lower_position: 5,
         left_thigh: 6,
         right_thigh: 7,
         left_buttock: 8,
         right_buttock: 9,
         nose: 10
       },
       prefix: true

  enum :outcome,
       {
         administered: 0,
         refused: 1,
         not_well: 2,
         contraindications: 3,
         already_had: 4,
         absent_from_session: 6
       },
       validate: true

  enum :source,
       {
         service: 0,
         historical_upload: 1,
         nhs_immunisations_api: 2,
         consent_refusal: 3
       },
       prefix: true,
       validate: true

  encrypts :notes

  validates :full_dose, inclusion: [true, false], if: :administered?
  validates :protocol,
            presence: true,
            if: -> { administered? && recorded_in_service? }

  validates :notes, length: { maximum: 1000 }

  validates :location_name,
            absence: {
              unless: :requires_location_name?
            },
            presence: {
              if: :requires_location_name?
            }

  validates :dose_sequence,
            comparison: {
              greater_than_or_equal_to: 1,
              less_than_or_equal_to: :maximum_dose_sequence,
              allow_nil: true
            }

  validates :performed_at,
            comparison: {
              less_than_or_equal_to: -> { Time.current }
            }

  after_save :sync_to_nhs_immunisations_api,
             if: :changes_need_to_be_synced_to_nhs_immunisations_api?

  delegate :fhir_record, to: :fhir_mapper

  class << self
    delegate :from_fhir_record, to: FHIRMapper::VaccinationRecord
  end

  def academic_year = performed_at.to_date.academic_year

  def not_administered?
    !administered?
  end

  def confirmation_sent?
    confirmation_sent_at != nil
  end

  def recorded_in_service?
    session_id != nil
  end

  def show_in_academic_year?(current_academic_year)
    if programme.seasonal?
      academic_year == current_academic_year
    else
      academic_year <= current_academic_year
    end
  end

  def delivery_method_snomed_code
    DELIVERY_METHOD_SNOMED_CODES_AND_TERMS.fetch(delivery_method).first
  end

  def delivery_method_snomed_term
    DELIVERY_METHOD_SNOMED_CODES_AND_TERMS.fetch(delivery_method).second
  end

  def snomed_procedure_code = vaccine&.snomed_procedure_code(dose_sequence:)

  delegate :snomed_procedure_term, to: :vaccine, allow_nil: true

  def create_or_update_reporting_api_vaccination_event!
    re =
      ReportingAPI::VaccinationEvent.find_or_initialize_by(
        source_id: id,
        source_type: self.class.name
      )
    re.event_timestamp = performed_at
    re.event_type = outcome

    re.copy_attributes_from_references(
      patient: patient.reload,
      patient_local_authority_from_postcode:
        patient.local_authority_from_postcode,
      patient_school: patient.school,
      patient_school_local_authority: patient.school&.local_authority,
      location:,
      location_local_authority: location&.local_authority,
      vaccination_record: self,
      vaccine:,
      team:,
      organisation: team.organisation,
      programme:
    )

    re.save!
    re
  end

  private

  def requires_location_name? = location.nil?

  delegate :maximum_dose_sequence, to: :programme

  def fhir_mapper
    @fhir_mapper ||= FHIRMapper::VaccinationRecord.new(self)
  end

  def changes_need_to_be_synced_to_nhs_immunisations_api?
    saved_changes.present? && !saved_change_to_nhs_immunisations_api_etag? &&
      !saved_change_to_nhs_immunisations_api_sync_pending_at? &&
      !saved_change_to_nhs_immunisations_api_synced_at? &&
      !saved_change_to_nhs_immunisations_api_id?
  end
end
