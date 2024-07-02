# frozen_string_literal: true

# == Schema Information
#
# Table name: consents
#
#  id                       :bigint           not null, primary key
#  health_answers           :jsonb
#  reason_for_refusal       :integer
#  reason_for_refusal_notes :text
#  recorded_at              :datetime
#  response                 :integer
#  route                    :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  campaign_id              :bigint           not null
#  parent_id                :bigint
#  patient_id               :bigint           not null
#  recorded_by_user_id      :bigint
#
# Indexes
#
#  index_consents_on_campaign_id          (campaign_id)
#  index_consents_on_parent_id            (parent_id)
#  index_consents_on_patient_id           (patient_id)
#  index_consents_on_recorded_by_user_id  (recorded_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (campaign_id => campaigns.id)
#  fk_rails_...  (parent_id => parents.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (recorded_by_user_id => users.id)
#

class Consent < ApplicationRecord
  include WizardFormConcern
  audited

  before_save :reset_unused_fields

  attr_accessor :triage

  has_one :consent_form
  belongs_to :parent, optional: true
  belongs_to :draft_parent,
             -> { draft },
             class_name: "Parent",
             optional: true,
             foreign_key: :parent_id
  belongs_to :patient
  belongs_to :campaign
  belongs_to :recorded_by,
             class_name: "User",
             optional: true,
             foreign_key: :recorded_by_user_id

  default_scope { recorded }

  scope :submitted_for_campaign,
        ->(campaign) { where(campaign:).where.not(recorded_at: nil) }
  scope :recorded, -> { where.not(recorded_at: nil) }
  scope :draft, -> { rewhere(recorded_at: nil) }

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
       prefix: true
  enum :route, %i[website phone paper in_person self_consent], prefix: "via"

  serialize :health_answers, coder: HealthAnswer::ArraySerializer

  encrypts :health_answers, :reason_for_refusal_notes

  validates :reason_for_refusal_notes, length: { maximum: 1000 }

  validates :route, presence: true, if: -> { recorded_at.present? }

  validates :parent,
            presence: true,
            if: -> { recorded_at.present? && !via_self_consent? }

  on_wizard_step :route do
    validates :route, inclusion: { in: Consent.routes.keys }, presence: true
  end

  on_wizard_step :parent_details do
    validate :draft_parent_present_unless_self_consent
  end

  on_wizard_step :agree do
    validates :response,
              inclusion: {
                in: Consent.responses.keys
              },
              presence: true
  end

  on_wizard_step :reason do
    validates :reason_for_refusal,
              inclusion: {
                in: Consent.reason_for_refusals.keys
              },
              presence: true
  end

  on_wizard_step :reason_notes do
    validates :reason_for_refusal_notes, presence: true
  end

  on_wizard_step :questions do
    validate :health_answers_valid?
  end

  on_wizard_step :triage, exact: true do
    validate :triage_valid?
  end

  def form_steps
    [
      (:parent_details unless via_self_consent?),
      (:route unless via_self_consent?),
      :agree,
      (:questions if response_given?),
      (:triage if response_given?),
      (:reason if response_refused?),
      (:reason_notes if response_refused? && reason_notes_required?),
      :confirm
    ].compact
  end

  def name
    via_self_consent? ? patient.full_name : parent.name
  end

  def triage_needed?
    response_given? && health_answers_require_follow_up?
  end

  def who_responded
    if via_self_consent?
      "Child (Gillick competent)"
    else
      (draft_parent || parent).relationship_label
    end
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

  def self.from_consent_form!(consent_form, patient_session)
    ActiveRecord::Base.transaction do
      parent = consent_form.parent.dup

      consent =
        create!(
          consent_form:,
          campaign: consent_form.session.campaign,
          patient: patient_session.patient,
          parent:,
          reason_for_refusal: consent_form.reason,
          reason_for_refusal_notes: consent_form.reason_notes,
          recorded_at: Time.zone.now,
          response: consent_form.response,
          route: "website",
          health_answers: consent_form.health_answers
        )
      patient_session.do_consent! if patient_session.may_do_consent?
      consent
    end
  end

  def reason_notes_required?
    reason_for_refusal_contains_gelatine? ||
      reason_for_refusal_already_vaccinated? ||
      reason_for_refusal_will_be_vaccinated_elsewhere? ||
      reason_for_refusal_medical_reasons? || reason_for_refusal_other?
  end

  def recorded?
    recorded_at.present?
  end

  private

  def draft_parent_present_unless_self_consent
    if recorded_at.nil? && !via_self_consent? && draft_parent.nil?
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
      self.reason_for_refusal_notes = nil

      seed_health_questions
    elsif response_refused?
      self.health_answers = []
    end
  end

  def seed_health_questions
    return unless health_answers.empty?
    vaccine = campaign.vaccines.first # assumes all vaccines in the campaign have the same questions
    self.health_answers = vaccine.health_questions.to_health_answers
  end
end
