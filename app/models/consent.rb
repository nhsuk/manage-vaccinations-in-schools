# frozen_string_literal: true

# == Schema Information
#
# Table name: consents
#
#  id                  :bigint           not null, primary key
#  health_answers      :jsonb
#  invalidated_at      :datetime
#  notes               :text             default(""), not null
#  reason_for_refusal  :integer
#  recorded_at         :datetime
#  response            :integer
#  route               :integer
#  withdrawn_at        :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  organisation_id     :bigint           not null
#  parent_id           :bigint
#  patient_id          :bigint           not null
#  programme_id        :bigint           not null
#  recorded_by_user_id :bigint
#
# Indexes
#
#  index_consents_on_organisation_id      (organisation_id)
#  index_consents_on_parent_id            (parent_id)
#  index_consents_on_patient_id           (patient_id)
#  index_consents_on_programme_id         (programme_id)
#  index_consents_on_recorded_by_user_id  (recorded_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#  fk_rails_...  (parent_id => parents.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (recorded_by_user_id => users.id)
#

class Consent < ApplicationRecord
  include Invalidatable
  include Recordable
  include WizardStepConcern

  audited

  before_save :reset_unused_fields

  attr_reader :new_or_existing_parent
  attr_accessor :triage, :triage_allowed

  belongs_to :patient
  belongs_to :programme
  belongs_to :organisation

  has_one :consent_form
  belongs_to :parent, -> { recorded }, optional: true
  belongs_to :draft_parent,
             -> { draft },
             class_name: "Parent",
             optional: true,
             foreign_key: :parent_id
  belongs_to :recorded_by,
             class_name: "User",
             optional: true,
             foreign_key: :recorded_by_user_id

  scope :for_patient, -> { where("patient_id = patients.id") }

  scope :withdrawn, -> { where.not(withdrawn_at: nil) }
  scope :not_withdrawn, -> { where(withdrawn_at: nil) }

  enum :response, %w[given refused not_provided], prefix: true
  enum :reason_for_refusal,
       %w[
         contains_gelatine
         already_vaccinated
         will_be_vaccinated_elsewhere
         medical_reasons
         personal_choice
         other
       ],
       prefix: true,
       validate: {
         if: :withdrawn?
       }

  enum :route, %i[website phone paper in_person self_consent], prefix: "via"

  serialize :health_answers, coder: HealthAnswer::ArraySerializer

  encrypts :health_answers, :notes

  validates :notes,
            presence: {
              if: -> { required_for_step?(:notes) && notes_required? },
              on: :update
            },
            length: {
              maximum: 1000
            }

  validates :route, presence: true, if: :recorded?

  validates :parent, presence: true, if: -> { recorded? && !via_self_consent? }

  on_wizard_step :route do
    validates :route, inclusion: { in: Consent.routes.keys }
  end

  on_wizard_step :who, exact: true do
    validates :new_or_existing_parent, presence: true
  end

  on_wizard_step :parent_details do
    validate :parent_present_unless_self_consent
  end

  on_wizard_step :agree do
    validates :response, inclusion: { in: Consent.responses.keys }
  end

  on_wizard_step :reason do
    validates :reason_for_refusal,
              inclusion: {
                in: Consent.reason_for_refusals.keys
              }
  end

  on_wizard_step :questions do
    validate :health_answers_valid?
  end

  on_wizard_step :triage, exact: true do
    validate :triage_valid?
  end

  def wizard_steps
    [
      (:who unless via_self_consent?),
      (:parent_details unless via_self_consent?),
      (:route unless via_self_consent?),
      :agree,
      (:questions if response_given?),
      (:triage if triage_allowed && response_given?),
      (:reason if response_refused?),
      (:notes if notes_required?),
      :confirm
    ].compact
  end

  delegate :restricted?, to: :patient

  def name
    via_self_consent? ? patient.full_name : parent.label
  end

  def withdrawn?
    withdrawn_at != nil
  end

  def not_withdrawn?
    withdrawn_at.nil?
  end

  def can_withdraw?
    Flipper.enabled?(:release_1b) && not_withdrawn? && not_invalidated? &&
      recorded? && response_given?
  end

  def can_invalidate?
    Flipper.enabled?(:release_1b) && not_invalidated? && recorded?
  end

  def responded_at
    invalidated_at || withdrawn_at || recorded_at
  end

  def triage_needed?
    response_given? && health_answers_require_follow_up?
  end

  def contactable?
    parent&.contactable? || false
  end

  def parent_relationship
    (draft_parent || parent)&.relationship_to(patient:)
  end

  def who_responded
    via_self_consent? ? "Child (Gillick competent)" : parent_relationship.label
  end

  def health_answers_require_follow_up?
    health_answers&.any? { |question| question.response&.downcase == "yes" }
  end

  def reasons_triage_needed
    reasons = []
    if health_answers_require_follow_up?
      reasons << "Health questions need triage"
    end
    reasons
  end

  def self.from_consent_form!(consent_form, patient:)
    ActiveRecord::Base.transaction do
      parent =
        consent_form.find_or_create_parent_with_relationship_to!(patient:)

      create!(
        consent_form:,
        organisation: consent_form.organisation,
        programme: consent_form.programme,
        patient:,
        parent:,
        reason_for_refusal: consent_form.reason,
        notes: consent_form.reason_notes.presence || "",
        recorded_at: Time.zone.now,
        response: consent_form.response,
        route: "website",
        health_answers: consent_form.health_answers
      )
    end
  end

  def notes_required?
    withdrawn? || invalidated? ||
      (
        response_refused? && reason_for_refusal_contains_gelatine? ||
          reason_for_refusal_already_vaccinated? ||
          reason_for_refusal_will_be_vaccinated_elsewhere? ||
          reason_for_refusal_medical_reasons? || reason_for_refusal_other?
      )
  end

  def new_or_existing_parent=(value)
    @new_or_existing_parent = value
    self.parent_id = value if value.to_i.in?(
      patient.consents.pluck(:parent_id) + patient.parents.pluck(:id)
    )
  end

  private

  def parent_present_unless_self_consent
    if draft? && !via_self_consent? && draft_parent.nil? && parent.nil?
      errors.add(:draft_parent, :blank)
    end
  end

  def health_answers_valid?
    return if health_answers.map(&:valid?).all?

    health_answers.each_with_index do |health_answer, index|
      health_answer.errors.messages.each do |field, messages|
        messages.each do |message|
          errors.add("question-#{index}-#{field}", message)
        end
      end
    end
  end

  def triage_valid?
    return if triage.valid?(:consent)

    triage.errors.each do |error|
      errors.add(:"triage_#{error.attribute}", error.message)
    end
  end

  def reset_unused_fields
    if response_given?
      self.reason_for_refusal = nil
      self.notes = "" unless invalidated?

      seed_health_questions
    elsif response_refused?
      self.health_answers = []
    end
  end

  def seed_health_questions
    return unless health_answers.empty?
    vaccine = programme.vaccines.first # assumes all vaccines in the programme have the same questions
    self.health_answers = vaccine.health_questions.to_health_answers
  end
end
