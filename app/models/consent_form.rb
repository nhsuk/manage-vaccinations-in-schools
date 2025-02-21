# frozen_string_literal: true

# == Schema Information
#
# Table name: consent_forms
#
#  id                                  :bigint           not null, primary key
#  address_line_1                      :string
#  address_line_2                      :string
#  address_postcode                    :string
#  address_town                        :string
#  archived_at                         :datetime
#  contact_injection                   :boolean
#  date_of_birth                       :date
#  education_setting                   :integer
#  family_name                         :text
#  given_name                          :text
#  health_answers                      :jsonb            not null
#  nhs_number                          :string
#  notes                               :text             default(""), not null
#  parent_contact_method_other_details :string
#  parent_contact_method_type          :string
#  parent_email                        :string
#  parent_full_name                    :string
#  parent_phone                        :string
#  parent_phone_receive_updates        :boolean          default(FALSE), not null
#  parent_relationship_other_name      :string
#  parent_relationship_type            :string
#  preferred_family_name               :string
#  preferred_given_name                :string
#  reason                              :integer
#  reason_notes                        :text
#  recorded_at                         :datetime
#  response                            :integer
#  school_confirmed                    :boolean
#  use_preferred_name                  :boolean
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  consent_id                          :bigint
#  location_id                         :bigint           not null
#  organisation_id                     :bigint           not null
#  school_id                           :bigint
#
# Indexes
#
#  index_consent_forms_on_consent_id       (consent_id)
#  index_consent_forms_on_location_id      (location_id)
#  index_consent_forms_on_nhs_number       (nhs_number)
#  index_consent_forms_on_organisation_id  (organisation_id)
#  index_consent_forms_on_school_id        (school_id)
#
# Foreign Keys
#
#  fk_rails_...  (consent_id => consents.id)
#  fk_rails_...  (location_id => locations.id)
#  fk_rails_...  (organisation_id => organisations.id)
#  fk_rails_...  (school_id => locations.id)
#

class ConsentForm < ApplicationRecord
  include AddressConcern
  include AgeConcern
  include Archivable
  include FullNameConcern
  include WizardStepConcern

  before_save :reset_unused_fields

  scope :unmatched, -> { where(consent_id: nil) }
  scope :recorded, -> { where.not(recorded_at: nil) }

  attr_accessor :health_question_number, :parental_responsibility

  audited

  belongs_to :consent, optional: true
  belongs_to :location
  belongs_to :school, class_name: "Location", optional: true
  belongs_to :organisation

  has_many :notify_log_entries
  has_many :consent_form_programmes,
           -> { joins(:programme).order(:"programme.type") },
           dependent: :destroy

  has_one :team, through: :location

  has_many :programmes, through: :consent_form_programmes
  has_many :eligible_schools, through: :organisation, source: :schools
  has_many :vaccines, through: :programmes

  enum :response, { given: 0, refused: 1, given_one: 2 }, prefix: "consent"
  enum :reason,
       {
         contains_gelatine: 0,
         already_vaccinated: 1,
         will_be_vaccinated_elsewhere: 2,
         medical_reasons: 3,
         personal_choice: 4,
         other: 5
       },
       prefix: "refused_because"

  enum :parent_contact_method_type,
       Parent.contact_method_types,
       prefix: :parent_contact_method,
       validate: {
         allow_nil: true
       }
  enum :parent_relationship_type,
       ParentRelationship.types,
       prefix: :parent_relationship,
       validate: {
         allow_nil: true
       }

  enum :education_setting, { school: 0, home: 1, none: 2 }, prefix: true

  serialize :health_answers, coder: HealthAnswer::ArraySerializer

  encrypts :address_line_1,
           :address_line_2,
           :address_postcode,
           :address_town,
           :family_name,
           :given_name,
           :health_answers,
           :parent_contact_method_other_details,
           :parent_email,
           :parent_full_name,
           :parent_phone,
           :parent_relationship_other_name,
           :preferred_family_name,
           :preferred_given_name,
           :reason_notes

  normalizes :given_name, with: -> { _1.strip }
  normalizes :family_name, with: -> { _1.strip }

  normalizes :parent_email, with: EmailAddressNormaliser.new
  normalizes :parent_phone, with: PhoneNumberNormaliser.new

  validates :address_line_1,
            :address_line_2,
            :address_town,
            :family_name,
            :given_name,
            :parent_contact_method_other_details,
            :parent_full_name,
            :parent_relationship_other_name,
            :preferred_family_name,
            :preferred_given_name,
            length: {
              maximum: 300
            }

  validates :parent_contact_method_other_details,
            presence: true,
            if: :parent_contact_method_other?

  validates :parent_phone,
            presence: {
              if: :parent_phone_receive_updates
            },
            phone: {
              allow_blank: true
            }

  validates :parent_relationship_other_name,
            presence: true,
            if: :parent_relationship_other?

  validates :reason_notes, length: { maximum: 1000 }

  validates :notes, presence: { if: :archived? }, length: { maximum: 1000 }

  normalizes :nhs_number, with: -> { _1.blank? ? nil : _1.gsub(/\s/, "") }

  on_wizard_step :name do
    validates :given_name, presence: true
    validates :family_name, presence: true
    validates :use_preferred_name, inclusion: { in: [true, false] }
    validates :preferred_given_name,
              presence: true,
              if: -> { use_preferred_name && preferred_family_name.blank? }
    validates :preferred_family_name,
              presence: true,
              if: -> { use_preferred_name && preferred_given_name.blank? }
  end

  on_wizard_step :date_of_birth do
    validates :date_of_birth,
              presence: true,
              comparison: {
                less_than: -> { Time.zone.today },
                greater_than_or_equal_to: -> { 22.years.ago.to_date },
                less_than_or_equal_to: -> { 3.years.ago.to_date }
              }
  end

  on_wizard_step :confirm_school do
    validates :school_confirmed, inclusion: { in: [true, false] }
  end

  on_wizard_step :education_setting do
    validates :education_setting, inclusion: { in: %w[school home none] }
  end

  on_wizard_step :school do
    validates :school_id,
              inclusion: {
                in: -> { _1.eligible_schools.pluck(:id) }
              },
              unless: -> { education_setting_home? || education_setting_none? }
  end

  on_wizard_step :parent do
    validates :parent_full_name, presence: true
    validates :parent_email, notify_safe_email: true
    validates :parent_relationship_type, presence: true
  end

  validates :parental_responsibility,
            inclusion: {
              in: ["yes"]
            },
            if: ->(object) do
              object.parent_relationship_other? && object.wizard_step == :parent
            end

  on_wizard_step :contact_method do
    validates :parent_contact_method_type, presence: true
  end

  on_wizard_step :consent do
    validates :response, presence: true
  end

  on_wizard_step :reason do
    validates :reason, presence: true
  end

  on_wizard_step :reason_notes do
    validates :reason_notes, presence: true
  end

  on_wizard_step :injection do
    validates :contact_injection, inclusion: { in: [true, false] }
  end

  on_wizard_step :address do
    validates :address_line_1, presence: true
    validates :address_town, presence: true
    validates :address_postcode, postcode: true
  end

  on_wizard_step :health_question do
    validate :health_answers_valid?
  end

  def wizard_steps
    [
      :name,
      :date_of_birth,
      (:confirm_school if location_is_school?),
      (:education_setting if location_is_clinic?),
      (:school if choose_school?),
      :parent,
      (:contact_method if parent_phone.present?),
      :consent,
      (:reason if consent_refused?),
      (:reason_notes if consent_refused? && reason_notes_must_be_provided?),
      (:injection if injection_offered_as_alternative?),
      (:address if consent_given? || consent_given_one?),
      (:health_question if consent_given? || consent_given_one?)
    ].compact
  end

  def each_health_answer
    return if health_answers.empty?
    return to_enum(:each_health_answer) unless block_given?

    health_answer = health_answers.first
    seen_health_answers = Set.new
    loop do
      if seen_health_answers.include?(health_answer.object_id)
        raise "Infinite loop detected"
      end
      seen_health_answers << health_answer.object_id

      yield health_answer
      next_health_answer_index = health_answer.next_health_answer_index
      break unless next_health_answer_index
      health_answer = health_answers[next_health_answer_index]
    end
  end

  def needs_triage?
    any_health_answers_truthy?
  end

  def any_health_answers_truthy?
    health_answers.any? { _1.response == "yes" }
  end

  def gelatine_content_status_in_vaccines
    # we don't YET track the vaccine type that the user is agreeing to in the consent form,
    # so we have to check all vaccines
    # there might not be a true or false answer if there are multiple vaccines in the programme
    # (e.g. flu nasal and flu injection)
    possible_answers = vaccines.map(&:contains_gelatine?)
    if possible_answers.uniq.length == 1
      possible_answers.first
    else
      :maybe
    end
  end

  def reason_notes_must_be_provided?
    refused_because_other? || refused_because_will_be_vaccinated_elsewhere? ||
      refused_because_medical_reasons? || refused_because_already_vaccinated?
  end

  def original_session
    # The session that the consent form was filled out for.
    @original_session ||=
      Session
        .joins(:programmes)
        .where(programmes:)
        .preload(:programmes)
        .find_by(academic_year:, location:, organisation:)
  end

  def actual_session
    # The session that the patient is expected to be seen in.
    @actual_session ||=
      (location_is_clinic? && original_session) ||
        (
          school &&
            school
              .sessions
              .includes(:session_dates)
              .for_current_academic_year
              .first
        ) || organisation.generic_clinic_session
  end

  def find_or_create_parent_with_relationship_to!(patient:)
    parent =
      Parent.match_existing(
        patient:,
        email: parent_email,
        phone: parent_phone,
        full_name: parent_full_name
      ) || Parent.new

    parent.update!(
      email: parent_email,
      full_name: parent_full_name,
      phone: parent_phone,
      phone_receive_updates: parent_phone_receive_updates
    )

    patient
      .parent_relationships
      .find_or_initialize_by(parent:)
      .update!(
        type: parent_relationship_type,
        other_name: parent_relationship_other_name
      )

    parent
  end

  def summary_with_route
    "#{human_enum_name(:response).capitalize} (online)"
  end

  def parent_contact_method_description
    Parent.new(
      contact_method_type: parent_contact_method_type,
      contact_method_other_details: parent_contact_method_other_details
    ).contact_method_description
  end

  def parent_relationship_label
    ParentRelationship.new(
      type: parent_relationship_type,
      other_name: parent_relationship_other_name
    ).label
  end

  def match_with_patient!(patient, current_user:)
    ActiveRecord::Base.transaction do
      notify_log_entries.update_all(patient_id: patient.id)

      school_changed =
        patient.school != school || patient.home_educated != home_educated

      if school_changed && !patient.deceased? && !patient.invalidated?
        school_move =
          if school
            SchoolMove.find_or_initialize_by(patient:, school:)
          else
            SchoolMove.find_or_initialize_by(
              patient:,
              home_educated:,
              organisation:
            )
          end

        school_move.update!(source: :parental_consent_form)
      end

      Consent.from_consent_form!(self, patient:, current_user:)
    end
  end

  def home_educated
    return nil if education_setting_school?

    education_setting_home?
  end

  private

  def academic_year
    created_at.to_date.academic_year
  end

  def refused_and_not_had_it_already?
    consent_refused? && !refused_because_will_be_vaccinated_elsewhere? &&
      !refused_because_already_vaccinated?
  end

  def injection_offered_as_alternative?
    refused_and_not_had_it_already? && programmes.any?(&:flu?)
    # checking for flu here is a simplification
    # the actual logic is: if the parent has refused a nasal vaccine AND the session is for a nasal vaccine
    # AND the SAIS organisation offers an alternative injection vaccine, then show the injection step
    #
    # we currently don't track what type of vaccine was refused.
    # currently HPV is only offered as an injection, so we don't need to check for it
    #
    # so a more true-to-life implementation would be:
    # refused_nasal? && not_had_it_already? && injection_offered_as_alternative?
  end

  def health_answers_valid?
    if health_question_number.present?
      unless health_answers[health_question_number].valid?
        errors.add(:base, "Health answer(s) invalid")
        return false
      end
    else
      each_health_answer do |health_answer|
        unless health_answer.valid?
          errors.add(:base, "Health answer(s) invalid")
          return false
        end
      end
    end
    true
  end

  def location_is_school?
    location.school?
  end

  def location_is_clinic?
    location.clinic?
  end

  def choose_school?
    location_is_clinic? ? education_setting_school? : !school_confirmed
  end

  # Because there are branching paths in the consent form journey, fields
  # sometimes get set with values that then have to be deleted if the user
  # changes their mind and goes down a different path.
  def reset_unused_fields
    unless use_preferred_name
      self.preferred_given_name = nil
      self.preferred_family_name = nil
    end

    if consent_refused?
      self.address_line_1 = nil
      self.address_line_2 = nil
      self.address_town = nil
      self.address_postcode = nil

      self.health_answers = []
    end

    self.parent_contact_method_type = nil if parent_phone.blank?
    self.parent_contact_method_other_details =
      nil unless parent_contact_method_other?

    self.parent_relationship_other_name = nil unless parent_relationship_other?

    if consent_given?
      self.contact_injection = nil

      self.reason = nil
      self.reason_notes = nil

      seed_health_questions
    end

    if school_confirmed
      self.education_setting = "school"
      self.school = location
    elsif education_setting_home? || education_setting_none?
      self.school = nil
      self.school_confirmed = false
    elsif school
      self.education_setting = "school"
    end
  end

  def seed_health_questions
    return unless health_answers.empty?

    # TODO: handle multiple active vaccines
    vaccine = vaccines.select(&:active?).first

    self.health_answers = vaccine.health_questions.to_health_answers
  end
end
