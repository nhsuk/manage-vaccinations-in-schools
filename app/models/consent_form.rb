# == Schema Information
#
# Table name: consent_forms
#
#  id                        :bigint           not null, primary key
#  address_line_1            :string
#  address_line_2            :string
#  address_postcode          :string
#  address_town              :string
#  common_name               :text
#  contact_injection         :boolean
#  contact_method            :integer
#  contact_method_other      :text
#  date_of_birth             :date
#  first_name                :text
#  gp_name                   :string
#  gp_response               :integer
#  health_answers            :jsonb            not null
#  last_name                 :text
#  parent_email              :string
#  parent_name               :string
#  parent_phone              :string
#  parent_relationship       :integer
#  parent_relationship_other :string
#  reason                    :integer
#  reason_notes              :text
#  recorded_at               :datetime
#  response                  :integer
#  use_common_name           :boolean
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  consent_id                :bigint
#  session_id                :bigint           not null
#
# Indexes
#
#  index_consent_forms_on_consent_id  (consent_id)
#  index_consent_forms_on_session_id  (session_id)
#
# Foreign Keys
#
#  fk_rails_...  (consent_id => consents.id)
#  fk_rails_...  (session_id => sessions.id)
#

class ConsentForm < ApplicationRecord
  include WizardFormConcern
  include AgeConcern

  before_save :remove_health_questions_if_consent_refused

  scope :unmatched, -> { where(consent_id: nil) }
  scope :recorded, -> { where.not(recorded_at: nil) }

  attr_accessor :health_question_number,
                :is_this_their_school,
                :parental_responsibility

  audited

  belongs_to :consent, optional: true
  belongs_to :session
  has_one :campaign, through: :session
  has_one :team, through: :campaign

  enum :parent_relationship, %w[mother father guardian other], prefix: true
  enum :contact_method, %w[text voice other any], prefix: true
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

  serialize :health_answers, coder: HealthAnswer::ArraySerializer

  encrypts :address_line_1,
           :address_line_2,
           :address_postcode,
           :address_town,
           :common_name,
           :contact_method_other,
           :first_name,
           :gp_name,
           :health_answers,
           :last_name,
           :parent_email,
           :parent_name,
           :parent_phone,
           :parent_relationship_other,
           :reason_notes

  validates :address_line_1,
            :address_line_2,
            :address_town,
            :common_name,
            :contact_method_other,
            :first_name,
            :gp_name,
            :last_name,
            :parent_email,
            :parent_name,
            :parent_phone,
            :parent_relationship_other,
            length: {
              maximum: 300
            }

  validates :reason_notes, length: { maximum: 1000 }

  on_wizard_step :name do
    validates :first_name, presence: true
    validates :last_name, presence: true
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

  on_wizard_step :school, exact: true do
    validates :is_this_their_school,
              presence: true,
              inclusion: {
                in: %w[yes no]
              }
  end

  on_wizard_step :parent do
    validates :parent_name, presence: true
    validates :parent_relationship, presence: true
    validates :parent_relationship_other,
              presence: true,
              if: :parent_relationship_other?
    validates :parent_email, presence: true, email: true
    validates :parent_phone, phone: true, if: :parent_phone?
  end

  validates :parental_responsibility,
            inclusion: {
              in: %w[yes]
            },
            if: ->(object) do
              object.parent_relationship_other? && object.form_step == :parent
            end

  on_wizard_step :contact_method, exact: true do
    validates :contact_method, presence: true
    validates :contact_method_other, presence: true, if: :contact_method_other?
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
    validates :address_postcode, presence: true, postcode: true
  end

  on_wizard_step :health_question do
    validate :health_answers_valid?
  end

  def address_postcode=(str)
    super UKPostcode.parse(str.to_s).to_s
  end

  def full_name
    [first_name, last_name].join(" ")
  end

  def form_steps
    [
      :name,
      :date_of_birth,
      :school,
      :parent,
      (:contact_method if ask_for_contact_method?),
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

  def who_responded
    if parent_relationship == "other"
      parent_relationship_other
    else
      human_enum_name(:parent_relationship)
    end.capitalize
  end

  def gelatine_content_status_in_vaccines
    # we don't YET track the vaccine type that the user is agreeing to in the consent form,
    # so we have to check all vaccines
    # there might not be a true or false answer if there are multiple vaccines in the campaign
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

  def address_fields
    [address_line_1, address_line_2, address_town, address_postcode].reject(
      &:blank?
    )
  end

  def find_matching_patient
    sp = session.patients
    patients =
      sp
        .where(first_name:, last_name:, date_of_birth:)
        .or(sp.where(first_name:, last_name:, address_postcode:))
        .or(sp.where(first_name:, date_of_birth:, address_postcode:))
        .or(sp.where(last_name:, date_of_birth:, address_postcode:))

    return nil if patients.count > 1

    patients.first
  end

  private

  def refused_and_not_had_it_already?
    consent_refused? && !refused_because_will_be_vaccinated_elsewhere? &&
      !refused_because_already_vaccinated?
  end

  def injection_offered_as_alternative?
    refused_and_not_had_it_already? && session.campaign.name == "Flu"
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

  def vaccines
    session.campaign.vaccines
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

  def ask_for_contact_method?
    Flipper.enabled?(:parent_contact_method) && parent_phone.present?
  end

  def remove_health_questions_if_consent_refused
    return unless consent_refused? || health_answers.empty?
    self.health_answers = []
  end
end
