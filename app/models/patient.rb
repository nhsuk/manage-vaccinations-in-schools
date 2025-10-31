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
#  index_patients_on_family_name_trigram        (family_name) USING gin
#  index_patients_on_given_name_trigram         (given_name) USING gin
#  index_patients_on_gp_practice_id             (gp_practice_id)
#  index_patients_on_names_family_first         (family_name,given_name)
#  index_patients_on_names_given_first          (given_name,family_name)
#  index_patients_on_nhs_number                 (nhs_number) UNIQUE
#  index_patients_on_pending_changes_not_empty  (id) WHERE (pending_changes <> '{}'::jsonb)
#  index_patients_on_school_id                  (school_id)
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
  has_many :attendance_records
  has_many :changesets, class_name: "PatientChangeset"
  has_many :consent_notifications
  has_many :consent_statuses
  has_many :consents
  has_many :gillick_assessments
  has_many :notes
  has_many :notify_log_entries
  has_many :parent_relationships, -> { order(:created_at) }
  has_many :patient_locations
  has_many :pds_search_results
  has_many :pre_screenings
  has_many :registration_statuses
  has_many :school_move_log_entries
  has_many :school_moves
  has_many :session_notifications
  has_many :triage_statuses
  has_many :triages
  has_many :vaccination_records, -> { kept }
  has_many :vaccination_statuses
  has_many :patient_specific_directions

  has_many :locations, through: :patient_locations
  has_many :location_programme_year_groups, through: :locations
  has_many :parents, through: :parent_relationships

  has_and_belongs_to_many :class_imports
  has_and_belongs_to_many :cohort_imports
  has_and_belongs_to_many :immunisation_imports

  # https://www.datadictionary.nhs.uk/attributes/person_gender_code.html
  enum :gender_code, { not_known: 0, male: 1, female: 2, not_specified: 9 }

  scope :joins_archive_reasons,
        ->(team:) do
          joins(
            "LEFT OUTER JOIN archive_reasons " \
              "ON archive_reasons.patient_id = patients.id " \
              "AND archive_reasons.team_id = #{team.id}"
          )
        end

  scope :joins_sessions, -> { joins(:patient_locations).joins(<<-SQL) }
    INNER JOIN sessions
    ON sessions.location_id = patient_locations.location_id
    AND sessions.academic_year = patient_locations.academic_year
  SQL

  scope :in_eligible_year_group_for_session_programme, -> { joins(<<-SQL) }
    INNER JOIN session_programmes ON session_programmes.session_id = sessions.id
    INNER JOIN location_year_groups ON location_year_groups.location_id = patient_locations.location_id
    AND location_year_groups.academic_year = patient_locations.academic_year
    INNER JOIN location_programme_year_groups ON location_programme_year_groups.location_year_group_id = location_year_groups.id
    AND location_programme_year_groups.programme_id = session_programmes.programme_id
    AND patients.birth_academic_year = location_year_groups.academic_year - location_year_groups.value - #{Integer::AGE_CHILDREN_START_SCHOOL}
  SQL

  scope :archived,
        ->(team:) do
          joins_archive_reasons(team:).where("archive_reasons.id IS NOT NULL")
        end

  scope :not_archived,
        ->(team:) do
          joins_archive_reasons(team:).where("archive_reasons.id IS NULL")
        end

  scope :with_pending_changes_for_team,
        ->(team:) { with_pending_changes.not_archived(team:) }

  scope :with_nhs_number, -> { where.not(nhs_number: nil) }
  scope :without_nhs_number, -> { where(nhs_number: nil) }

  scope :deceased, -> { where.not(date_of_death: nil) }
  scope :not_deceased, -> { where(date_of_death: nil) }
  scope :restricted, -> { where.not(restricted_at: nil) }

  scope :has_vaccination_records_dont_notify_parents,
        -> do
          where(
            VaccinationRecord
              .kept
              .where("patient_id = patients.id")
              .where(notify_parents: false)
              .arel
              .exists
          )
        end

  scope :appear_in_programmes,
        ->(programmes, academic_year: nil, session: nil) do
          if session
            birth_academic_years =
              programmes.flat_map do |programme|
                session.programme_year_groups.birth_academic_years(programme)
              end

            where(birth_academic_year: birth_academic_years)
          elsif academic_year
            patient_locations =
              PatientLocation
                .select("1")
                .where("patient_locations.patient_id = patients.id")
                .where(academic_year:)
                .appear_in_programmes(programmes)

            where(patient_locations.arel.exists)
          else
            raise "Pass either academic year or session."
          end
        end

  scope :not_appear_in_programmes,
        ->(programmes, academic_year:) do
          patient_locations =
            PatientLocation
              .select("1")
              .where("patient_locations.patient_id = patients.id")
              .where(academic_year:)
              .appear_in_programmes(programmes)

          where.not(patient_locations.arel.exists)
        end

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
              .select("1")
              .where("patient_id = patients.id")
              .where(status:, programme:, academic_year:)
              .arel
              .exists
          )
        end

  scope :has_consent_status,
        ->(
          status,
          programme:,
          academic_year:,
          vaccine_method: nil,
          without_gelatine: nil
        ) do
          consent_status_scope =
            Patient::ConsentStatus
              .select("1")
              .where("patient_id = patients.id")
              .where(status:, programme:, academic_year:)

          unless vaccine_method.nil?
            consent_status_scope =
              consent_status_scope.has_vaccine_method(vaccine_method)
          end

          unless without_gelatine.nil?
            consent_status_scope = consent_status_scope.where(without_gelatine:)
          end

          where(consent_status_scope.arel.exists)
        end

  scope :has_triage_status,
        ->(status, programme:, academic_year:) do
          where(
            Patient::TriageStatus
              .select("1")
              .where("patient_id = patients.id")
              .where(status:, programme:, academic_year:)
              .arel
              .exists
          )
        end

  scope :has_vaccine_criteria,
        ->(
          programme:,
          academic_year:,
          vaccine_method: nil,
          without_gelatine: nil
        ) do
          triage_status_matching =
            Patient::TriageStatus
              .select("1")
              .where("patient_id = patients.id")
              .where(programme:, academic_year:)
              .then { vaccine_method ? it.where(vaccine_method:) : it }
              .then { without_gelatine ? it.where(without_gelatine:) : it }

          triage_status_not_required =
            Patient::TriageStatus
              .select("1")
              .where("patient_id = patients.id")
              .where(programme:, academic_year:)
              .where(status: "not_required")

          consent_status_matching =
            Patient::ConsentStatus
              .select("1")
              .where("patient_id = patients.id")
              .where(programme:, academic_year:)
              .then { without_gelatine ? it.where(without_gelatine:) : it }
              .then do
                vaccine_method ? it.has_vaccine_method(vaccine_method) : it
              end

          where(triage_status_matching.arel.exists).or(
            where(triage_status_not_required.arel.exists).where(
              consent_status_matching.arel.exists
            )
          )
        end

  scope :has_registration_status,
        ->(status, session:) do
          where(
            Patient::RegistrationStatus
              .select("1")
              .where("patient_id = patients.id")
              .where(session:, status:)
              .arel
              .exists
          )
        end

  scope :with_patient_specific_direction,
        ->(programme:, academic_year:, team:) do
          where(
            PatientSpecificDirection
              .select("1")
              .where("patient_id = patients.id")
              .where(programme:, academic_year:, team:)
              .not_invalidated
              .arel
              .exists
          )
        end

  scope :without_patient_specific_direction,
        ->(programme:, academic_year:, team:) do
          where.not(
            PatientSpecificDirection
              .select("1")
              .where("patient_id = patients.id")
              .where(programme:, academic_year:, team:)
              .not_invalidated
              .arel
              .exists
          )
        end

  scope :consent_given_and_safe_to_vaccinate,
        ->(programmes:, academic_year:, vaccine_method:, without_gelatine:) do
          select do |patient|
            programmes.any? do |programme|
              patient.consent_given_and_safe_to_vaccinate?(
                programme:,
                academic_year:,
                vaccine_method:,
                without_gelatine:
              )
            end
          end
        end

  scope :eligible_for_programmes,
        ->(programmes, location:, academic_year:) do
          # We exclude patients who were vaccinated in a previous
          # academic year, or vaccinated at a different location.

          not_eligible_criteria =
            programmes.map do |programme|
              vaccinated_statuses =
                Patient::VaccinationStatus
                  .select("1")
                  .where("patient_id = patients.id")
                  .where(programme:)
                  .vaccinated

              scope =
                vaccinated_statuses
                  .where(academic_year:)
                  .where.not(latest_location: location)

              unless programme.seasonal?
                scope =
                  scope.or(
                    vaccinated_statuses.where(academic_year: academic_year - 1)
                  )
              end

              scope
            end

          # TODO: Handle multiple programmes.
          where.not(not_eligible_criteria.first.arel.exists)
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
  after_commit :search_vaccinations_from_nhs_immunisations_api, on: :update
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

  def sessions
    Session
      .joins_patient_locations
      .joins_patients
      .joins(:session_programmes)
      .joins_location_programme_year_groups
      .where(patients: { id: })
      .distinct
  end

  def teams
    Team.distinct.joins(:sessions).joins(<<-SQL)
      INNER JOIN patient_locations
      ON patient_locations.patient_id = #{id}
      AND patient_locations.location_id = sessions.location_id
      AND patient_locations.academic_year = sessions.academic_year
    SQL
  end

  def archived?(team:)
    archive_reasons.exists?(team:)
  end

  def not_archived?(team:)
    !archive_reasons.exists?(team:)
  end

  def year_group(academic_year:)
    birth_academic_year.to_year_group(academic_year:)
  end

  def year_group_changed? = birth_academic_year_changed?

  def show_year_group?(team:)
    academic_year = AcademicYear.pending
    year_group = self.year_group(academic_year:)
    programme_year_groups =
      school&.programme_year_groups(academic_year:) ||
        team.programme_year_groups(academic_year:)

    team.programmes.any? do |programme|
      programme_year_groups[programme].include?(year_group)
    end
  end

  def consent_status(programme:, academic_year:)
    patient_status(consent_statuses, programme:, academic_year:)
  end

  def registration_status(session:)
    registration_statuses.find { it.session_id == session.id } ||
      registration_statuses.build(session:)
  end

  def triage_status(programme:, academic_year:)
    patient_status(triage_statuses, programme:, academic_year:)
  end

  def vaccination_status(programme:, academic_year:)
    patient_status(vaccination_statuses, programme:, academic_year:)
  end

  def has_patient_specific_direction?(team:, **kwargs)
    patient_specific_directions.not_invalidated.where(team:, **kwargs).exists?
  end

  def consent_given_and_safe_to_vaccinate?(
    programme:,
    academic_year:,
    vaccine_method: nil,
    without_gelatine: nil
  )
    return false if vaccination_status(programme:, academic_year:).vaccinated?

    return false unless consent_status(programme:, academic_year:).given?

    unless triage_status(programme:, academic_year:).safe_to_vaccinate? ||
             triage_status(programme:, academic_year:).not_required?
      return false
    end

    return true if vaccine_method.nil? && without_gelatine.nil?

    vaccine_criteria = self.vaccine_criteria(programme:, academic_year:)

    if vaccine_method &&
         vaccine_criteria.vaccine_methods.first != vaccine_method
      return false
    end

    if !without_gelatine.nil? &&
         vaccine_criteria.without_gelatine != without_gelatine
      return false
    end

    true
  end

  def next_activity(programme:, academic_year:)
    return nil if vaccination_status(programme:, academic_year:).vaccinated?

    if consent_given_and_safe_to_vaccinate?(programme:, academic_year:)
      return :record
    end

    return :triage if triage_status(programme:, academic_year:).required?

    consent_status = consent_status(programme:, academic_year:)

    return :consent if consent_status.no_response? || consent_status.conflicts?

    :do_not_record
  end

  def vaccine_criteria(programme:, academic_year:)
    triage_status = triage_status(programme:, academic_year:)

    if triage_status.not_required?
      VaccineCriteria.from_consent_status(
        consent_status(programme:, academic_year:)
      )
    else
      VaccineCriteria.from_triage_status(triage_status)
    end
  end

  def deceased?
    date_of_death != nil
  end

  def restricted?
    restricted_at != nil
  end

  def send_notifications?(team:, send_to_archived: false)
    !deceased? && !restricted? && !invalidated? &&
      (send_to_archived || not_archived?(team:))
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

  def not_in_team?(team:, academic_year:)
    patient_locations
      .joins(location: :subteam)
      .where(academic_year:, subteams: { team_id: team.id })
      .empty?
  end

  def dup_for_pending_changes
    dup.tap do |new_patient|
      new_patient.nhs_number = nil

      patient_locations.pending.find_each do |patient_location|
        new_patient.patient_locations.build(
          **patient_location.slice(:academic_year, :location_id)
        )
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
    scope = patient_locations.pending

    unless team.nil?
      scope = scope.joins_sessions.where("sessions.team_id = ?", team.id)
    end

    scope.destroy_all_if_safe
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

  def latest_pds_search_result
    nhs_numbers =
      pds_search_results.latest_set&.pluck(:nhs_number)&.compact&.uniq
    nhs_numbers&.one? ? nhs_numbers.first : nil
  end

  def pds_lookup_match?
    nhs_number.present? && nhs_number == latest_pds_search_result
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

    ArchiveReason.import!(
      archive_reasons,
      on_duplicate_key_update: {
        conflict_target: %i[team_id patient_id],
        columns: %i[type]
      }
    )
  end

  def fhir_mapper = @fhir_mapper ||= FHIRMapper::Patient.new(self)

  def should_sync_vaccinations_to_nhs_immunisations_api?
    nhs_number_previously_changed? || invalidated_at_previously_changed?
  end

  def sync_vaccinations_to_nhs_immunisations_api
    if should_sync_vaccinations_to_nhs_immunisations_api?
      vaccination_records.sync_all_to_nhs_immunisations_api
    end
  end

  def should_search_vaccinations_from_nhs_immunisations_api?
    nhs_number_previously_changed?
  end

  def search_vaccinations_from_nhs_immunisations_api
    if should_search_vaccinations_from_nhs_immunisations_api?
      SearchVaccinationRecordsInNHSJob.perform_async(id)
    end
  end
end
