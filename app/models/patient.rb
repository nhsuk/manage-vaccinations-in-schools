# frozen_string_literal: true

# == Schema Information
#
# Table name: patients
#
#  id               :bigint           not null, primary key
#  address_line_1   :string
#  address_line_2   :string
#  address_postcode :string           not null
#  address_town     :string
#  common_name      :string
#  date_of_birth    :date             not null
#  first_name       :string           not null
#  gender_code      :integer          default("not_known"), not null
#  home_educated    :boolean
#  last_name        :string           not null
#  nhs_number       :string
#  pending_changes  :jsonb            not null
#  recorded_at      :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  cohort_id        :bigint           not null
#  school_id        :bigint
#
# Indexes
#
#  index_patients_on_cohort_id   (cohort_id)
#  index_patients_on_nhs_number  (nhs_number) UNIQUE
#  index_patients_on_school_id   (school_id)
#
# Foreign Keys
#
#  fk_rails_...  (cohort_id => cohorts.id)
#  fk_rails_...  (school_id => locations.id)
#
class Patient < ApplicationRecord
  include AddressConcern
  include AgeConcern
  include PendingChangesConcern
  include Recordable

  audited

  belongs_to :cohort
  belongs_to :school, class_name: "Location", optional: true

  has_many :consent_notifications
  has_many :consents
  has_many :parent_relationships
  has_many :patient_sessions
  has_many :session_notifications

  has_many :sessions, through: :patient_sessions
  has_many :triage, through: :patient_sessions
  has_many :vaccination_records, through: :patient_sessions
  has_many :parents, through: :parent_relationships
  has_many :programmes, through: :sessions

  has_and_belongs_to_many :class_imports
  has_and_belongs_to_many :cohort_imports
  has_and_belongs_to_many :immunisation_imports

  # https://www.datadictionary.nhs.uk/attributes/person_gender_code.html
  enum :gender_code, { not_known: 0, male: 1, female: 2, not_specified: 9 }

  scope :matching_three_of,
        ->(first_name:, last_name:, date_of_birth:, address_postcode:) do
          where(first_name:, last_name:, date_of_birth:)
            .or(Patient.where(first_name:, last_name:, address_postcode:))
            .or(Patient.where(first_name:, date_of_birth:, address_postcode:))
            .or(Patient.where(last_name:, date_of_birth:, address_postcode:))
        end

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :date_of_birth, presence: true
  validates :nhs_number,
            uniqueness: true,
            format: {
              with: /\A(?:\d\s*){10}\z/
            },
            allow_nil: true
  validates :school, absence: true, if: :home_educated
  validate :school_is_correct_type

  encrypts :first_name,
           :last_name,
           :common_name,
           :address_postcode,
           :nhs_number,
           deterministic: true

  encrypts :address_line_1, :address_line_2, :address_town

  before_save :remove_spaces_from_nhs_number

  before_destroy :destroy_childless_parents

  delegate :year_group, to: :cohort

  def self.find_existing(
    nhs_number:,
    first_name:,
    last_name:,
    date_of_birth:,
    address_postcode:
  )
    if nhs_number.present? && (patient = Patient.find_by(nhs_number:)).present?
      return [patient]
    end

    Patient.matching_three_of(
      first_name:,
      last_name:,
      date_of_birth:,
      address_postcode:
    ).to_a
  end

  def relationship_to(parent:)
    parent_relationships.find { _1.parent == parent }
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def has_consent?(programme)
    consents.any? { _1.programme_id == programme.id }
  end

  def as_json(options = {})
    super.merge("full_name" => full_name, "age" => age)
  end

  def match_consent_form!(consent_form)
    ActiveRecord::Base.transaction do
      new_school = consent_form.school

      session_in_new_school =
        (
          if new_school && new_school != school
            move_school(
              new_school,
              existing_session: consent_form.scheduled_session,
              programme: consent_form.programme
            )
          end
        )

      Consent.from_consent_form!(consent_form, patient: self)

      session_in_new_school
    end
  end

  private

  def move_school(new_school, existing_session:, programme:)
    update!(school: new_school)

    existing_patient_session =
      existing_session.patient_sessions.find_by(patient: self)

    if existing_patient_session&.added_to_session?
      existing_patient_session.destroy!
    end

    new_session =
      Session
        .where(location: new_school, team: existing_session.team)
        .has_programme(programme)
        .scheduled
        .or(
          Session.unscheduled.where(academic_year: Date.current.academic_year)
        )
        .first

    new_session&.patient_sessions&.create!(patient: self)

    new_session
  end

  def remove_spaces_from_nhs_number
    nhs_number&.gsub!(/\s/, "")
  end

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
end
