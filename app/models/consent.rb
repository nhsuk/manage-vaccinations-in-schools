# frozen_string_literal: true

# == Schema Information
#
# Table name: consents
#
#  id                  :bigint           not null, primary key
#  health_answers      :jsonb
#  invalidated_at      :datetime
#  notes               :text             default(""), not null
#  notify_parents      :boolean
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

  audited

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
              if: :notes_required?
            },
            length: {
              maximum: 1000
            }

  validates :route, presence: true, if: :recorded?

  validates :parent, presence: true, if: -> { recorded? && !via_self_consent? }

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

  def parent_relationship
    (parent || draft_parent)&.relationship_to(patient:)
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
      (response_refused? && !reason_for_refusal_personal_choice?)
  end

  private

  def parent_present_unless_self_consent
    if draft? && !via_self_consent? && draft_parent.nil? && parent.nil?
      errors.add(:draft_parent, :blank)
    end
  end
end
