# frozen_string_literal: true

# == Schema Information
#
# Table name: patients
#
#  id                         :bigint           not null, primary key
#  address_line_1             :string
#  address_line_2             :string
#  address_postcode           :string
#  address_town               :string
#  birth_academic_year        :integer          not null
#  date_of_birth              :date             not null
#  date_of_death              :date
#  date_of_death_recorded_at  :datetime
#  family_name                :string           not null
#  gender_code                :integer          default("not_known"), not null
#  given_name                 :string           not null
#  home_educated              :boolean
#  invalidated_at             :datetime
#  nhs_number                 :string
#  pending_changes            :jsonb            not null
#  preferred_family_name      :string
#  preferred_given_name       :string
#  registration               :string
#  registration_academic_year :integer
#  restricted_at              :datetime
#  updated_from_pds_at        :datetime
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  gp_practice_id             :bigint
#  school_id                  :bigint
#
# Indexes
#
#  index_patients_on_family_name_trigram  (family_name) USING gin
#  index_patients_on_given_name_trigram   (given_name) USING gin
#  index_patients_on_gp_practice_id       (gp_practice_id)
#  index_patients_on_names_family_first   (family_name,given_name)
#  index_patients_on_names_given_first    (given_name,family_name)
#  index_patients_on_nhs_number           (nhs_number) UNIQUE
#  index_patients_on_school_id            (school_id)
#
# Foreign Keys
#
#  fk_rails_...  (gp_practice_id => locations.id)
#  fk_rails_...  (school_id => locations.id)
#
class Patient < ApplicationRecord
  include AddressConcern
  include AgeConcern
  include FullNameConcern
  include Invalidatable
  include PendingChangesConcern
  include Schoolable

  audited
  has_associated_audits

  belongs_to :gp_practice, class_name: "Location", optional: true

  has_many :access_log_entries
  has_many :archive_reasons
  has_many :consent_notifications
  has_many :consent_statuses
  has_many :consents
  has_many :notes
  has_many :notify_log_entries
  has_many :parent_relationships, -> { order(:created_at) }
  has_many :patient_sessions
  has_many :school_move_log_entries
  has_many :school_moves
  has_many :session_notifications
  has_many :triage_statuses
  has_many :triages
  has_many :vaccination_records, -> { kept }
  has_many :vaccination_statuses

  has_many :gillick_assessments, through: :patient_sessions
  has_many :parents, through: :parent_relationships
  has_many :patient_specific_directions
  has_many :pre_screenings, through: :patient_sessions
  has_many :session_attendances, through: :patient_sessions
  has_many :sessions, through: :patient_sessions
  has_many :teams, -> { distinct }, through: :sessions

  has_many :pending_sessions,
           -> { where(academic_year: AcademicYear.pending) },
           through: :patient_sessions,
           source: :session

  has_and_belongs_to_many :class_imports
  has_and_belongs_to_many :cohort_imports
  has_and_belongs_to_many :immunisation_imports

  # https://www.datadictionary.nhs.uk/attributes/person_gender_code.html
  enum :gender_code, { not_known: 0, male: 1, female: 2, not_specified: 9 }

  scope :joins_archive_reasons,
        ->(team:) do
          joins(
            "LEFT JOIN archive_reasons " \
              "ON archive_reasons.patient_id = patients.id " \
              "AND archive_reasons.team_id = #{team.id}"
          )
        end

  scope :archived,
        ->(team:) do
          joins_archive_reasons(team:).where("archive_reasons.id IS NOT NULL")
        end

  scope :not_archived,
        ->(team:) do
          joins_archive_reasons(team:).where("archive_reasons.id IS NULL")
        end

  scope :with_nhs_number, -> { where.not(nhs_number: nil) }
  scope :without_nhs_number, -> { where(nhs_number: nil) }

  scope :deceased, -> { where.not(date_of_death: nil) }
  scope :not_deceased, -> { where(date_of_death: nil) }
  scope :restricted, -> { where.not(restricted_at: nil) }

  scope :has_vaccination_records_dont_notify_parents,
        -> do
          joins(:vaccination_records).where(
            vaccination_records: {
              notify_parents: false
            }
          ).distinct
        end

  scope :with_notice,
        -> do
          (
            deceased + restricted + invalidated +
              has_vaccination_records_dont_notify_parents
          ).uniq
        end

  scope :appear_in_programmes,
        ->(programmes, academic_year:) do
          where(
            PatientSession
              .joins(:session)
              .where(sessions: { academic_year: })
              .where("patient_id = patients.id")
              .appear_in_programmes(programmes)
              .arel
              .exists
          )
        end

  scope :not_appear_in_programmes,
        ->(programmes, academic_year:) do
          where.not(
            PatientSession
              .joins(:session)
              .where(sessions: { academic_year: })
              .where("patient_id = patients.id")
              .appear_in_programmes(programmes)
              .arel
              .exists
          )
        end

  scope :with_pending_changes, -> { where.not(pending_changes: {}) }

  scope :search_by_name,
        ->(query) do
          # Trigram matching requires at least 3 characters
          if query.length < 3
            where(
              "given_name ILIKE :like_query OR family_name ILIKE :like_query",
              like_query: "#{query}%"
            )
          else
            where(
              "SIMILARITY(CONCAT(given_name, ' ', family_name), :query) > 0.3 OR " \
                "SIMILARITY(CONCAT(family_name, ' ', given_name), :query) > 0.3",
              query:
            ).order(
              Arel.sql(
                "GREATEST(SIMILARITY(CONCAT(given_name, ' ', family_name), :query), " \
                  "SIMILARITY(CONCAT(family_name, ' ', given_name), :query)) DESC",
                query:
              )
            )
          end
        end

  scope :search_by_year_groups,
        ->(year_groups, academic_year:) do
          where(
            birth_academic_year:
              year_groups.map { it.to_birth_academic_year(academic_year:) }
          )
        end

  scope :search_by_date_of_birth_year,
        ->(year) { where("extract(year from date_of_birth) = ?", year) }

  scope :search_by_date_of_birth_month,
        ->(month) { where("extract(month from date_of_birth) = ?", month) }

  scope :search_by_date_of_birth_day,
        ->(day) { where("extract(day from date_of_birth) = ?", day) }

  scope :search_by_nhs_number, ->(nhs_number) { where(nhs_number:) }

  scope :has_vaccination_status,
        ->(status, programme:, academic_year:) do
          where(
            Patient::VaccinationStatus
              .where("patient_id = patients.id")
              .where(status:, programme:, academic_year:)
              .arel
              .exists
          )
        end

  scope :has_consent_status,
        ->(status, programme:, academic_year:) do
          where(
            Patient::ConsentStatus
              .where("patient_id = patients.id")
              .where(status:, programme:, academic_year:)
              .arel
              .exists
          )
        end

  scope :has_triage_status,
        ->(status, programme:, academic_year:) do
          where(
            Patient::TriageStatus
              .where("patient_id = patients.id")
              .where(status:, programme:, academic_year:)
              .arel
              .exists
          )
        end

  validates :given_name, :family_name, :date_of_birth, presence: true

  validates :birth_academic_year, comparison: { greater_than_or_equal_to: 1990 }

  validates :nhs_number, nhs_number: true, uniqueness: true, allow_nil: true

  validates :address_postcode, postcode: { allow_nil: true }

  validate :gp_practice_is_correct_type

  validates :birth_academic_year, comparison: { greater_than_or_equal_to: 1990 }

  encrypts :preferred_family_name,
           :preferred_given_name,
           :address_postcode,
           :nhs_number,
           deterministic: true

  encrypts :address_line_1, :address_line_2, :address_town

  normalizes :nhs_number,
             with: -> do
               it.blank? ? nil : it.normalise_whitespace.gsub(/\s/, "")
             end

  after_update :sync_vaccinations_to_nhs_immunisations_api
  before_destroy :destroy_childless_parents

  delegate :fhir_record, to: :fhir_mapper

  def self.match_existing(
    nhs_number:,
    given_name:,
    family_name:,
    date_of_birth:,
    address_postcode:
  )
    if nhs_number.present? && (patient = Patient.find_by(nhs_number:)).present?
      return [patient]
    end

    scope =
      Patient.where(
        "given_name ILIKE ? AND family_name ILIKE ?",
        given_name,
        family_name
      ).where(date_of_birth:)

    if address_postcode.present?
      scope =
        scope
          .or(
            Patient.where(
              "given_name ILIKE ? AND family_name ILIKE ?",
              given_name,
              family_name
            ).where(address_postcode:)
          )
          .or(
            Patient.where("given_name ILIKE ?", given_name).where(
              date_of_birth:,
              address_postcode:
            )
          )
          .or(
            Patient.where("family_name ILIKE ?", family_name).where(
              date_of_birth:,
              address_postcode:
            )
          )
    end

    results =
      if nhs_number.blank?
        scope.to_a
      else
        # This prevents us from finding a patient that happens to have at least
        # three of the other fields the same, but with a different NHS number,
        # and therefore cannot be a match.
        Patient.where(nhs_number: nil).merge(scope).to_a
      end

    if address_postcode.present?
      # Check for an exact match of all four datapoints, we do this in memory
      # to avoid an extra query to the database for each record.
      exact_results =
        results.select do
          it.given_name.downcase == given_name.downcase &&
            it.family_name.downcase == family_name.downcase &&
            it.date_of_birth == date_of_birth &&
            it.address_postcode == UKPostcode.parse(address_postcode).to_s
        end

      return exact_results if exact_results.length == 1
    end

    results
  end

  def archived?(team:)
    archive_reasons.exists?(team:)
  end

  def not_archived?(team:)
    !archive_reasons.exists?(team:)
  end

  def year_group(academic_year: nil)
    academic_year ||= AcademicYear.current
    birth_academic_year.to_year_group(academic_year:)
  end

  def year_group_changed? = birth_academic_year_changed?

  def show_year_group?(team:)
    academic_year = AcademicYear.pending
    year_group = self.year_group(academic_year:)
    programme_year_groups =
      school&.programme_year_groups || team.programme_year_groups

    team.programmes.any? do |programme|
      programme_year_groups[programme].include?(year_group)
    end
  end

  def consent_status(programme:, academic_year:)
    patient_status(consent_statuses, programme:, academic_year:)
  end

  def triage_status(programme:, academic_year:)
    patient_status(triage_statuses, programme:, academic_year:)
  end

  def vaccination_status(programme:, academic_year:)
    patient_status(vaccination_statuses, programme:, academic_year:)
  end

  def consent_given_and_safe_to_vaccinate?(
    programme:,
    academic_year:,
    vaccine_method: nil
  )
    return false if vaccination_status(programme:, academic_year:).vaccinated?

    return false unless consent_status(programme:, academic_year:).given?

    unless triage_status(programme:, academic_year:).safe_to_vaccinate? ||
             triage_status(programme:, academic_year:).not_required?
      return false
    end

    if vaccine_method &&
         approved_vaccine_methods(programme:, academic_year:).first !=
           vaccine_method
      return false
    end

    true
  end

  def approved_vaccine_methods(programme:, academic_year:)
    triage_status = triage_status(programme:, academic_year:)

    if triage_status.not_required?
      consent_status(programme:, academic_year:).vaccine_methods
    else
      [triage_status.vaccine_method].compact
    end
  end

  def deceased?
    date_of_death != nil
  end

  def restricted?
    restricted_at != nil
  end

  def send_notifications?
    !deceased? && !restricted? && !invalidated?
  end

  def update_from_pds!(pds_patient)
    if nhs_number.nil? || nhs_number != pds_patient.nhs_number
      raise NHSNumberMismatch
    end

    ActiveRecord::Base.transaction do
      self.date_of_death = pds_patient.date_of_death

      if date_of_death_changed?
        if date_of_death.present?
          archive_due_to_deceased!
          clear_pending_sessions!
        end

        self.date_of_death_recorded_at = Time.current
      end

      # If we've got a response from PDS we know the patient is valid,
      # otherwise PDS will return a 404 status.
      self.invalidated_at = nil if invalidated?

      if pds_patient.restricted
        self.restricted_at = Time.current unless restricted?
      else
        self.restricted_at = nil
      end

      if (ods_code = pds_patient.gp_ods_code).present?
        if (gp_practice = Location.gp_practice.find_by(ods_code:))
          self.gp_practice = gp_practice
        elsif Settings.pds.raise_unknown_gp_practice
          Sentry.capture_exception(UnknownGPPractice.new(ods_code))
        end
      else
        self.gp_practice = nil
      end

      self.updated_from_pds_at = Time.current

      save!
    end
  end

  def invalidate!
    return if invalidated?

    update!(invalidated_at: Time.current)
  end

  def not_in_team? = patient_sessions.empty?

  def dup_for_pending_changes
    dup.tap do |new_patient|
      new_patient.nhs_number = nil

      pending_sessions.each do |session|
        new_patient.patient_sessions.build(session:)
      end

      school_moves.each do |school_move|
        new_patient.school_moves.build(
          academic_year: school_move.academic_year,
          home_educated: school_move.home_educated,
          school_id: school_move.school_id,
          source: school_move.source,
          team_id: school_move.team_id
        )
      end
    end
  end

  def clear_pending_sessions!(team: nil)
    sessions = pending_sessions

    sessions = sessions.where(team_id: team.id) unless team.nil?

    patient_sessions.where(session: sessions).destroy_all_if_safe
  end

  def self.from_consent_form(consent_form)
    new(
      address_line_1: consent_form.address_line_1,
      address_line_2: consent_form.address_line_2,
      address_postcode: consent_form.address_postcode,
      address_town: consent_form.address_town,
      birth_academic_year: consent_form.date_of_birth.academic_year,
      date_of_birth: consent_form.date_of_birth,
      family_name: consent_form.family_name,
      given_name: consent_form.given_name,
      home_educated: consent_form.home_educated,
      nhs_number: consent_form.nhs_number,
      preferred_family_name: consent_form.preferred_family_name,
      preferred_given_name: consent_form.preferred_given_name,
      school: consent_form.school
    )
  end

  class NHSNumberMismatch < StandardError
  end

  class UnknownGPPractice < StandardError
  end

  private

  def patient_status(association, programme:, academic_year:)
    association.find do
      it.programme_id == programme.id && it.academic_year == academic_year
    end || association.build(programme:, academic_year:)
  end

  def gp_practice_is_correct_type
    location = gp_practice
    if location && !location.gp_practice?
      errors.add(:gp_practice, "must be a GP practice location type")
    end
  end

  def destroy_childless_parents
    parents_to_check = parents.to_a # Store parents before destroying relationships

    # Manually destroy the parent_relationships associated with this Child
    parent_relationships.each(&:destroy)

    parents_to_check.each do |parent|
      parent.destroy! if parent.parent_relationships.count.zero?
    end
  end

  def archive_due_to_deceased!
    archive_reasons =
      teams.map do |team|
        ArchiveReason.new(team:, patient: self, type: :deceased)
      end

    ArchiveReason.import!(archive_reasons, on_duplicate_key_update: :all)
  end

  def fhir_mapper = @fhir_mapper ||= FHIRMapper::Patient.new(self)

  def should_sync_vaccinations_to_nhs_immunisations_api?
    nhs_number_previously_changed? || invalidated_at_previously_changed?
  end

  def sync_vaccinations_to_nhs_immunisations_api
    if should_sync_vaccinations_to_nhs_immunisations_api?
      vaccination_records.syncable_to_nhs_immunisations_api.find_each(
        &:sync_to_nhs_immunisations_api
      )
    end
  end
end
