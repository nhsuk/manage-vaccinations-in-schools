# frozen_string_literal: true

# == Schema Information
#
# Table name: consent_forms
#
#  id                                  :bigint           not null, primary key
#  academic_year                       :integer          not null
#  address_line_1                      :string
#  address_line_2                      :string
#  address_postcode                    :string
#  address_town                        :string
#  archived_at                         :datetime
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
#  school_confirmed                    :boolean
#  use_preferred_name                  :boolean
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  consent_id                          :bigint
#  location_id                         :bigint           not null
#  school_id                           :bigint
#  team_id                             :bigint           not null
#
# Indexes
#
#  index_consent_forms_on_academic_year  (academic_year)
#  index_consent_forms_on_consent_id     (consent_id)
#  index_consent_forms_on_location_id    (location_id)
#  index_consent_forms_on_nhs_number     (nhs_number)
#  index_consent_forms_on_school_id      (school_id)
#  index_consent_forms_on_team_id        (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (consent_id => consents.id)
#  fk_rails_...  (location_id => locations.id)
#  fk_rails_...  (school_id => locations.id)
#  fk_rails_...  (team_id => teams.id)
#

class ConsentForm < ApplicationRecord
  include AddressConcern
  include AgeConcern
  include Archivable
  include FullNameConcern
  include GelatineVaccinesConcern
  include HasHealthAnswers
  include WizardStepConcern

  before_save :reset_unused_attributes

  scope :unmatched, -> { where(consent_id: nil) }
  scope :recorded, -> { where.not(recorded_at: nil) }

  attr_accessor :health_question_number,
                :parental_responsibility,
                :response,
                :chosen_programme,
                :injection_alternative

  audited associated_with: :consent
  has_associated_audits

  belongs_to :consent, optional: true
  belongs_to :location
  belongs_to :school, class_name: "Location", optional: true
  belongs_to :team

  has_many :notify_log_entries
  has_many :consent_form_programmes,
           -> { ordered },
           dependent: :destroy,
           autosave: true

  has_many :given_consent_form_programmes,
           -> { ordered.response_given },
           class_name: "ConsentFormProgramme"
  has_many :refused_consent_form_programmes,
           -> { ordered.response_refused },
           class_name: "ConsentFormProgramme"

  has_many :programmes, through: :consent_form_programmes
  has_many :given_programmes,
           through: :given_consent_form_programmes,
           source: :programme
  has_many :refused_programmes,
           through: :refused_consent_form_programmes,
           source: :programme

  has_one :subteam, through: :location

  has_many :eligible_schools, through: :team, source: :schools
  has_many :vaccines, through: :programmes

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

  encrypts :address_line_1,
           :address_line_2,
           :address_postcode,
           :address_town,
           :family_name,
           :given_name,
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
                in: -> { it.eligible_schools.pluck(:id) }
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

  on_wizard_step :response_doubles, exact: true do
    validates :response, inclusion: %w[given given_one refused]
    validates :chosen_programme,
              presence: true,
              if: -> { response == "given_one" }
  end

  on_wizard_step :response_flu, exact: true do
    validates :response, inclusion: %w[given_injection given_nasal refused]
  end

  on_wizard_step :response_hpv, exact: true do
    validates :response, inclusion: %w[given refused]
  end

  on_wizard_step :injection_alternative, exact: true do
    validates :injection_alternative, inclusion: %w[true false]
  end

  on_wizard_step :reason do
    validates :reason, presence: true
  end

  on_wizard_step :reason_notes do
    validates :reason_notes, presence: true
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
    refused_and_not_given = response_refused? && !response_given?
    refused_and_given = response_refused? && response_given?

    response_steps =
      ProgrammeGrouper.call(programmes).keys.map { :"response_#{it}" }

    [
      :name,
      :date_of_birth,
      (:confirm_school if location_is_school?),
      (:education_setting if location_is_clinic?),
      (:school if choose_school?),
      :parent,
      (:contact_method if parent_phone.present?)
    ].compact + response_steps +
      [
        (:reason if refused_and_not_given),
        (
          if refused_and_not_given && reason_notes_must_be_provided?
            :reason_notes
          end
        ),
        (:injection_alternative if can_offer_injection_as_alternative?),
        (:address if response_given?),
        (:health_question if response_given?),
        (:reason if refused_and_given),
        (:reason_notes if refused_and_given && reason_notes_must_be_provided?)
      ].compact
  end

  def recorded? = recorded_at != nil

  def response_given? = consent_form_programmes.any?(&:response_given?)

  def response_refused? = consent_form_programmes.any?(&:response_refused?)

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

  def can_offer_injection_as_alternative?
    consent_form_programmes.select(&:response_given?).any?(
      &:vaccine_method_nasal?
    )
  end

  def reason_notes_must_be_provided?
    reason.in?(Consent::REASON_FOR_REFUSAL_REQUIRES_NOTES)
  end

  def original_session
    # The session that the consent form was filled out for.
    @original_session ||=
      Session
        .joins(:programmes)
        .where(programmes:)
        .preload(:programmes)
        .find_by(academic_year:, location:, team:)
  end

  def actual_session
    # The session that the patient is expected to be seen in.
    @actual_session ||=
      (location_is_clinic? && original_session) ||
        (
          school &&
            school
              .sessions
              .has_programmes(programmes)
              .includes(:session_dates)
              .find_by(academic_year:)
        ) || team.generic_clinic_session(academic_year:)
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
      contact_method_other_details: parent_contact_method_other_details,
      contact_method_type: parent_contact_method_type,
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
    if response_given? && response_refused?
      "Partial consent given (online)"
    elsif response_given?
      "Consent given (online)"
    elsif response_refused?
      "Consent refused (online)"
    end
  end

  def parent
    Parent.new(
      full_name: parent_full_name,
      email: parent_email,
      phone: parent_phone,
      phone_receive_updates: parent_phone_receive_updates,
      contact_method_type: parent_contact_method_type,
      contact_method_other_details: parent_contact_method_other_details
    )
  end

  def parent_relationship
    ParentRelationship.new(
      parent:,
      type: parent_relationship_type,
      other_name: parent_relationship_other_name
    )
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
            SchoolMove.find_or_initialize_by(patient:, home_educated:, team:)
          end

        school_move.update!(academic_year:, source: :parental_consent_form)
      end

      Consent
        .from_consent_form!(self, patient:, current_user:)
        .each do |consent|
          next unless consent.requires_triage?
          patient
            .triages
            .where(academic_year:, programme: consent.programme)
            .invalidate_all
        end
    end
  end

  def home_educated
    return nil if education_setting_school?

    education_setting_home?
  end

  def home_educated_changed?
    education_setting_changed?
  end

  def update_programme_responses
    case response
    when "given", "given_injection"
      consent_form_programmes.each do
        it.response = "given"
        it.vaccine_methods = %w[injection]
      end
    when "given_nasal"
      consent_form_programmes.each do
        it.response = "given"
        it.vaccine_methods = %w[nasal]
      end
    when "given_one"
      consent_form_programmes.each do |consent_form_programme|
        consent_form_programme.response =
          if consent_form_programme.programme.type == chosen_programme
            "given"
          else
            "refused"
          end
        consent_form_programme.vaccine_methods = %w[injection]
      end
    when "refused"
      consent_form_programmes.each { it.response = "refused" }
    end
  end

  def update_injection_alternative
    vaccine_methods =
      if ActiveModel::Type::Boolean.new.cast(injection_alternative)
        %w[nasal injection]
      else
        %w[nasal]
      end

    consent_form_programmes.each do |consent_form_programme|
      if consent_form_programme.vaccine_method_nasal?
        consent_form_programme.vaccine_methods = vaccine_methods
      end
    end
  end

  def seed_health_questions
    return unless response_given?

    # If the health answers change due to the chosen vaccines changing, we
    # want to try and keep as much as what the parents already wrote intact.
    # We do this be saving the answers to the question title (as the IDs
    # and ordering can change).

    existing_health_answers =
      health_answers.each_with_object({}) do |health_answer, memo|
        memo[health_answer.question] = {
          response: health_answer.response,
          notes: health_answer.notes
        }
      end

    vaccines =
      consent_form_programmes.select(&:response_given?).flat_map(&:vaccines)

    self.health_answers =
      HealthAnswersDeduplicator
        .call(vaccines:)
        .map do |health_answer|
          if (
               existing_health_answer =
                 existing_health_answers[health_answer.question]
             )
            health_answer.response = existing_health_answer[:response]
            health_answer.notes = existing_health_answer[:notes]
          end

          health_answer
        end
  end

  private

  def via_self_consent?
    false
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

  def reset_unused_attributes
    update_programme_responses

    unless use_preferred_name
      self.preferred_given_name = nil
      self.preferred_family_name = nil
    end

    if response_refused? && !response_given?
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

    if response_given? && !response_refused?
      self.reason = nil
      self.reason_notes = nil
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
end
