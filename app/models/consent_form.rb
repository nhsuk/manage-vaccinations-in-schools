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
#  common_name                         :text
#  contact_injection                   :boolean
#  date_of_birth                       :date
#  family_name                         :text
#  given_name                          :text
#  gp_name                             :string
#  gp_response                         :integer
#  health_answers                      :jsonb            not null
#  parent_contact_method_other_details :string
#  parent_contact_method_type          :string
#  parent_email                        :string
#  parent_full_name                    :string
#  parent_phone                        :string
#  parent_phone_receive_updates        :boolean          default(FALSE), not null
#  parent_relationship_other_name      :string
#  parent_relationship_type            :string
#  reason                              :integer
#  reason_notes                        :text
#  recorded_at                         :datetime
#  response                            :integer
#  school_confirmed                    :boolean
#  use_common_name                     :boolean
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  consent_id                          :bigint
#  location_id                         :bigint           not null
#  programme_id                        :bigint           not null
#  school_id                           :bigint
#  team_id                             :bigint           not null
#
# Indexes
#
#  index_consent_forms_on_consent_id    (consent_id)
#  index_consent_forms_on_location_id   (location_id)
#  index_consent_forms_on_programme_id  (programme_id)
#  index_consent_forms_on_school_id     (school_id)
#  index_consent_forms_on_team_id       (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (consent_id => consents.id)
#  fk_rails_...  (location_id => locations.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (school_id => locations.id)
#  fk_rails_...  (team_id => teams.id)
#

class ConsentForm < ApplicationRecord
  include AddressConcern
  include AgeConcern
  include FullNameConcern
  include WizardStepConcern

  before_save :reset_unused_fields

  scope :unmatched, -> { where(consent_id: nil) }
  scope :recorded, -> { where.not(recorded_at: nil) }

  attr_accessor :health_question_number, :parental_responsibility

  audited

  belongs_to :consent, optional: true
  belongs_to :location
  belongs_to :programme
  belongs_to :school, class_name: "Location", optional: true
  belongs_to :team

  has_many :eligible_schools, through: :team, source: :schools

  enum :response, %w[given refused not_provided], prefix: "consent"
  enum :reason,
       %w[
         contains_gelatine
         already_vaccinated
         will_be_vaccinated_elsewhere
         medical_reasons
         personal_choice
         other
       ],
       prefix: "refused_because"
  enum :gp_response, %w[yes no dont_know], prefix: true

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

  serialize :health_answers, coder: HealthAnswer::ArraySerializer

  encrypts :address_line_1,
           :address_line_2,
           :address_postcode,
           :address_town,
           :common_name,
           :family_name,
           :given_name,
           :gp_name,
           :health_answers,
           :parent_contact_method_other_details,
           :parent_email,
           :parent_full_name,
           :parent_phone,
           :parent_relationship_other_name,
           :reason_notes

  normalizes :parent_phone,
             with: -> { _1.blank? ? nil : _1.to_s.gsub(/\s/, "") }
  normalizes :parent_email,
             with: -> { _1.blank? ? nil : _1.to_s.downcase.strip }

  validates :programme, inclusion: { in: -> { _1.team.programmes } }

  validates :address_line_1,
            :address_line_2,
            :address_town,
            :common_name,
            :family_name,
            :given_name,
            :gp_name,
            :parent_contact_method_other_details,
            :parent_full_name,
            :parent_relationship_other_name,
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

  on_wizard_step :name do
    validates :given_name, presence: true
    validates :family_name, presence: true
    validates :use_common_name, inclusion: { in: [true, false] }
    validates :common_name, presence: true, if: :use_common_name?
  end

  on_wizard_step :date_of_birth do
    validates :date_of_birth,
              presence: true,
              comparison: {
                less_than: Time.zone.today,
                greater_than_or_equal_to: 22.years.ago.to_date,
                less_than_or_equal_to: 3.years.ago.to_date
              }
  end

  on_wizard_step :confirm_school do
    validates :school_confirmed, inclusion: { in: [true, false] }
  end

  on_wizard_step :school do
    validates :school_id,
              inclusion: {
                in: -> { _1.eligible_schools.pluck(:id) }
              }
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

  on_wizard_step :gp do
    validates :gp_response, presence: true
    validates :gp_name, presence: true, if: :gp_response_yes?
  end

  on_wizard_step :address do
    validates :address_line_1, presence: true
    validates :address_town, presence: true
    validates :address_postcode, postcode: true
  end

  on_wizard_step :health_question do
    validate :health_answers_valid?
  end

  delegate :vaccines, to: :programme

  def wizard_steps
    [
      :name,
      :date_of_birth,
      :confirm_school,
      (:school if choose_school?),
      :parent,
      (:contact_method if parent_phone.present?),
      :consent,
      (:reason if consent_refused?),
      (:reason_notes if consent_refused? && reason_notes_must_be_provided?),
      (:injection if injection_offered_as_alternative?),
      (:gp if consent_given?),
      (:address if consent_given?),
      (:health_question if consent_given?)
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

  def scheduled_session
    @scheduled_session ||=
      Session.scheduled.has_programme(programme).find_by(team:, location:)
  end

  def find_or_create_parent_with_relationship_to!(patient:)
    parent =
      Parent.match_existing(
        patient:,
        email: parent_email,
        phone: parent_phone,
        full_name: parent_full_name
      ) || Parent.new

    parent.recorded_at = Time.current unless parent.recorded?

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

  def choose_school?
    !school_confirmed
  end

  def match_with_patient!(patient)
    ActiveRecord::Base.transaction do
      if school && school != patient.school
        patient.update!(school:)

        patient
          .patient_sessions
          .where(session: scheduled_session)
          .find_each(&:destroy_if_safe!)

        upcoming_session =
          Session
            .upcoming
            .has_programme(programme)
            .find_by(team:, location: school)

        if upcoming_session && patient.date_of_death.nil?
          patient.patient_sessions.find_or_create_by!(session: upcoming_session)
        end
      end

      Consent.from_consent_form!(self, patient:)
    end
  end

  private

  def refused_and_not_had_it_already?
    consent_refused? && !refused_because_will_be_vaccinated_elsewhere? &&
      !refused_because_already_vaccinated?
  end

  def injection_offered_as_alternative?
    refused_and_not_had_it_already? && programme.flu?
    # checking for flu here is a simplification
    # the actual logic is: if the parent has refused a nasal vaccine AND the session is for a nasal vaccine
    # AND the SAIS team offers an alternative injection vaccine, then show the injection step
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

  # Because there are branching paths in the consent form journey, fields
  # sometimes get set with values that then have to be deleted if the user
  # changes their mind and goes down a different path.
  def reset_unused_fields
    self.common_name = nil unless use_common_name?

    if consent_refused?
      self.gp_response = nil

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

    self.gp_name = nil unless gp_response_yes?
  end

  def seed_health_questions
    return unless health_answers.empty?

    # TODO: handle multiple active vaccines
    vaccine = programme.vaccines.active.first

    self.health_answers = vaccine.health_questions.to_health_answers
  end
end
