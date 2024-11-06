# frozen_string_literal: true

# == Schema Information
#
# Table name: patients
#
#  id                        :bigint           not null, primary key
#  address_line_1            :string
#  address_line_2            :string
#  address_postcode          :string
#  address_town              :string
#  date_of_birth             :date             not null
#  date_of_death             :date
#  date_of_death_recorded_at :datetime
#  family_name               :string           not null
#  gender_code               :integer          default("not_known"), not null
#  given_name                :string           not null
#  home_educated             :boolean
#  invalidated_at            :datetime
#  nhs_number                :string
#  pending_changes           :jsonb            not null
#  preferred_family_name     :string
#  preferred_given_name      :string
#  registration              :string
#  restricted_at             :datetime
#  updated_from_pds_at       :datetime
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  cohort_id                 :bigint
#  school_id                 :bigint
#
# Indexes
#
#  index_patients_on_cohort_id            (cohort_id)
#  index_patients_on_family_name_trigram  (family_name) USING gin
#  index_patients_on_given_name_trigram   (given_name) USING gin
#  index_patients_on_names_family_first   (family_name,given_name)
#  index_patients_on_names_given_first    (given_name,family_name)
#  index_patients_on_nhs_number           (nhs_number) UNIQUE
#  index_patients_on_school_id            (school_id)
#
# Foreign Keys
#
#  fk_rails_...  (cohort_id => cohorts.id)
#  fk_rails_...  (school_id => locations.id)
#
class Patient < ApplicationRecord
  include AddressConcern
  include AgeConcern
  include Invalidatable
  include FullNameConcern
  include PendingChangesConcern

  audited

  belongs_to :cohort, optional: true
  belongs_to :school, class_name: "Location", optional: true

  has_many :consent_notifications
  has_many :consents
  has_many :notify_log_entries
  has_many :parent_relationships
  has_many :patient_sessions
  has_many :session_notifications
  has_many :triages

  has_one :latest_triage, -> { order(created_at: :desc) }, class_name: "Triage"

  has_many :parents, through: :parent_relationships
  has_many :sessions, through: :patient_sessions
  has_many :vaccination_records, through: :patient_sessions

  has_many :upcoming_sessions,
           -> { upcoming },
           through: :patient_sessions,
           source: :session
  has_many :proposed_sessions,
           through: :patient_sessions,
           source: :proposed_session

  has_and_belongs_to_many :class_imports
  has_and_belongs_to_many :cohort_imports
  has_and_belongs_to_many :immunisation_imports

  # https://www.datadictionary.nhs.uk/attributes/person_gender_code.html
  enum :gender_code, { not_known: 0, male: 1, female: 2, not_specified: 9 }

  scope :with_nhs_number, -> { where.not(nhs_number: nil) }
  scope :without_nhs_number, -> { where(nhs_number: nil) }

  scope :not_deceased, -> { where(date_of_death: nil) }
  scope :deceased, -> { where.not(date_of_death: nil) }

  scope :not_restricted, -> { where(restricted_at: nil) }
  scope :restricted, -> { where.not(restricted_at: nil) }

  scope :unvaccinated_for,
        ->(programmes:) do
          reject do |patient|
            programmes.all? { |programme| patient.vaccinated?(programme) }
          end
        end

  scope :in_pending_cohorts,
        ->(cohorts) do
          where("pending_changes->>'cohort_id' IN (?)", cohorts.pluck(:id))
        end

  scope :in_pending_school,
        ->(school) { where("pending_changes->>'school_id' = ?", school.id) }

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
              "given_name % :query OR " \
                "family_name % :query OR " \
                "similarity(given_name, :query) > 0.3 OR " \
                "similarity(family_name, :query) > 0.3",
              query:
            )
          end
        end

  validates :given_name, :family_name, :date_of_birth, presence: true

  validates :nhs_number,
            uniqueness: true,
            format: {
              with: /\A(?:\d\s*){10}\z/
            },
            allow_nil: true
  validates :school, absence: true, if: :home_educated
  validate :school_is_correct_type

  validates :address_postcode, postcode: { allow_nil: true }

  encrypts :preferred_family_name,
           :preferred_given_name,
           :address_postcode,
           :nhs_number,
           deterministic: true

  encrypts :address_line_1, :address_line_2, :address_town

  normalizes :nhs_number, with: -> { _1.blank? ? nil : _1.gsub(/\s/, "") }

  before_destroy :destroy_childless_parents

  delegate :year_group, to: :cohort

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
          _1.given_name.downcase == given_name.downcase &&
            _1.family_name.downcase == family_name.downcase &&
            _1.date_of_birth == date_of_birth &&
            _1.address_postcode == UKPostcode.parse(address_postcode).to_s
        end

      return exact_results if exact_results.length == 1
    end

    results
  end

  def relationship_to(parent:)
    parent_relationships.find { _1.parent == parent }
  end

  def year_group
    cohort&.year_group || date_of_birth.year_group
  end

  def has_consent?(programme)
    consents.any? { _1.programme_id == programme.id }
  end

  def as_json(options = {})
    super.merge("full_name" => full_name, "age" => age)
  end

  def vaccinated?(programme)
    # TODO: This logic doesn't work for vaccinations that require multiple doses.

    vaccination_records.any? do
      _1.recorded? && _1.administered? && _1.programme_id == programme.id
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
        clear_upcoming_sessions unless date_of_death.nil?
        self.date_of_death_recorded_at = Time.current
      end

      # If we've got a response from DPS we know the patient is valid,
      # otherwise PDS will return a 404 status.
      self.invalidated_at = nil

      if pds_patient.restricted
        self.restricted_at = Time.current unless restricted?
      else
        self.restricted_at = nil
      end

      self.updated_from_pds_at = Time.current

      save!
    end
  end

  def invalidate!
    return if invalidated?

    ActiveRecord::Base.transaction do
      clear_upcoming_sessions
      update!(invalidated_at: Time.current)
    end
  end

  def move_to_session!(new_session, from:)
    return if deceased? || invalidated?

    old_session = from

    existing_patient_sessions = patient_sessions.where(session: old_session)

    if existing_patient_sessions.exists?
      existing_patient_sessions.update_all(proposed_session_id: new_session.id)
    else
      patient_sessions.find_or_create_by!(session_id: new_session.id)
    end
  end

  class NHSNumberMismatch < StandardError
  end

  private

  def school_is_correct_type
    location = school
    if location && !location.school?
      errors.add(:school, "must be a school location type")
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

  def clear_upcoming_sessions
    patient_sessions.where(session: upcoming_sessions).find_each(
      &:destroy_if_safe!
    )
  end

  def dup_for_pending_changes
    dup.tap { |record| record.nhs_number = nil }
  end
end
