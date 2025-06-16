# frozen_string_literal: true

# == Schema Information
#
# Table name: consents
#
#  id                  :bigint           not null, primary key
#  health_answers      :jsonb            not null
#  invalidated_at      :datetime
#  notes               :text             default(""), not null
#  notify_parents      :boolean
#  reason_for_refusal  :integer
#  response            :integer          not null
#  route               :integer          not null
#  submitted_at        :datetime         not null
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
  include HasHealthAnswers

  audited associated_with: :patient

  belongs_to :patient
  belongs_to :programme
  belongs_to :organisation

  has_one :consent_form
  belongs_to :parent, optional: true
  belongs_to :recorded_by,
             class_name: "User",
             optional: true,
             foreign_key: :recorded_by_user_id

  scope :withdrawn, -> { where.not(withdrawn_at: nil) }
  scope :not_withdrawn, -> { where(withdrawn_at: nil) }

  scope :response_provided, -> { not_response_not_provided }

  enum :response,
       { given: 0, refused: 1, not_provided: 2 },
       prefix: true,
       validate: true
  enum :route,
       { website: 0, phone: 1, paper: 2, in_person: 3, self_consent: 4 },
       prefix: "via",
       validate: true

  enum :reason_for_refusal,
       {
         contains_gelatine: 0,
         already_vaccinated: 1,
         will_be_vaccinated_elsewhere: 2,
         medical_reasons: 3,
         personal_choice: 4,
         other: 5
       },
       prefix: true,
       validate: {
         if: -> { response_refused? || withdrawn? }
       }

  encrypts :notes

  validates :notes,
            presence: {
              if: :notes_required?
            },
            length: {
              maximum: 1000
            }

  validates :parent, presence: true, unless: :via_self_consent?
  validates :recorded_by,
            presence: true,
            unless: -> { via_self_consent? || via_website? }

  def self.verbal_routes = routes.except("website", "self_consent")

  def name
    via_self_consent? ? patient.full_name : parent.label
  end

  def response_provided? = !response_not_provided?

  def withdrawn?
    withdrawn_at != nil
  end

  def not_withdrawn?
    withdrawn_at.nil?
  end

  def can_withdraw?
    not_withdrawn? && not_invalidated? && response_given?
  end

  def can_invalidate?
    not_invalidated?
  end

  def responded_at
    invalidated_at || withdrawn_at || submitted_at
  end

  def triage_needed?
    response_given? && health_answers_require_follow_up?
  end

  def parent_relationship
    patient.parent_relationships.find { it.parent_id == parent_id }
  end

  def health_answers_require_follow_up?
    health_answers.select(&:counts_for_triage?).any?(&:response_yes?)
  end

  def matched_manually?
    !consent_form.nil? && !recorded_by_user_id.nil?
  end

  def reasons_triage_needed
    reasons = []
    if health_answers_require_follow_up?
      reasons << "Health questions need triage"
    end
    reasons
  end

  def self.from_consent_form!(consent_form, patient:, current_user:)
    raise ConsentFormNotRecorded unless consent_form.recorded?

    ActiveRecord::Base.transaction do
      parent =
        consent_form.find_or_create_parent_with_relationship_to!(patient:)

      consent_given =
        consent_form.given_programmes.map do |programme|
          patient.consents.create!(
            consent_form:,
            organisation: consent_form.organisation,
            programme:,
            parent:,
            notes: "",
            response: "given",
            route: "website",
            health_answers: consent_form.health_answers,
            recorded_by: current_user,
            submitted_at: consent_form.recorded_at
          )
        end

      consent_refused =
        consent_form.refused_programmes.map do |programme|
          patient.consents.create!(
            consent_form:,
            organisation: consent_form.organisation,
            programme:,
            parent:,
            reason_for_refusal: consent_form.reason,
            notes: consent_form.reason_notes.presence || "",
            response: "refused",
            route: "website",
            health_answers: consent_form.health_answers,
            recorded_by: current_user,
            submitted_at: consent_form.recorded_at
          )
        end

      StatusUpdater.call(patient:)

      consent_given + consent_refused
    end
  end

  def notes_required?
    withdrawn? || invalidated? ||
      (response_refused? && !reason_for_refusal_personal_choice?)
  end

  class ConsentFormNotRecorded < StandardError
  end
end
