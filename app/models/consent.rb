# frozen_string_literal: true

# == Schema Information
#
# Table name: consents
#
#  id                            :bigint           not null, primary key
#  academic_year                 :integer          not null
#  health_answers                :jsonb            not null
#  invalidated_at                :datetime
#  notes                         :text             default(""), not null
#  notify_parent_on_refusal      :boolean
#  notify_parents_on_vaccination :boolean
#  reason_for_refusal            :integer
#  response                      :integer          not null
#  route                         :integer          not null
#  submitted_at                  :datetime         not null
#  vaccine_methods               :integer          default([]), not null, is an Array
#  withdrawn_at                  :datetime
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  consent_form_id               :bigint
#  parent_id                     :bigint
#  patient_id                    :bigint           not null
#  programme_id                  :bigint           not null
#  recorded_by_user_id           :bigint
#  team_id                       :bigint           not null
#
# Indexes
#
#  index_consents_on_academic_year        (academic_year)
#  index_consents_on_consent_form_id      (consent_form_id)
#  index_consents_on_parent_id            (parent_id)
#  index_consents_on_patient_id           (patient_id)
#  index_consents_on_programme_id         (programme_id)
#  index_consents_on_recorded_by_user_id  (recorded_by_user_id)
#  index_consents_on_team_id              (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (consent_form_id => consent_forms.id)
#  fk_rails_...  (parent_id => parents.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (recorded_by_user_id => users.id)
#  fk_rails_...  (team_id => teams.id)
#

class Consent < ApplicationRecord
  include GelatineVaccinesConcern
  include HasHealthAnswers
  include HasVaccineMethods
  include Invalidatable
  include Notable

  audited associated_with: :patient

  belongs_to :patient
  belongs_to :programme
  belongs_to :team

  belongs_to :consent_form, optional: true
  belongs_to :parent, optional: true
  belongs_to :recorded_by,
             class_name: "User",
             optional: true,
             foreign_key: :recorded_by_user_id

  has_many :vaccines, through: :programme

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

  validates :parent, presence: true, unless: :via_self_consent?
  validates :recorded_by,
            presence: true,
            unless: -> { via_self_consent? || via_website? }

  validates :vaccine_methods, presence: true, if: :response_given?

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

  def requires_triage?
    response_given? && health_answers_require_triage?
  end

  def parent_relationship
    patient.parent_relationships.find { it.parent_id == parent_id }
  end

  def matched_manually?
    !consent_form.nil? && !recorded_by_user_id.nil?
  end

  def self.from_consent_form!(consent_form, patient:, current_user:)
    raise ConsentFormNotRecorded unless consent_form.recorded?

    ActiveRecord::Base.transaction do
      parent =
        consent_form.find_or_create_parent_with_relationship_to!(patient:)

      consents =
        consent_form
          .consent_form_programmes
          .includes(:programme)
          .map do |consent_form_programme|
            notes =
              if consent_form_programme.response_given?
                ""
              else
                consent_form.reason_notes.presence || ""
              end
            reason_for_refusal =
              if consent_form_programme.response_given?
                nil
              else
                consent_form.reason
              end

            patient.consents.create!(
              consent_form:,
              health_answers: consent_form.health_answers,
              notes:,
              team: consent_form.team,
              parent:,
              programme: consent_form_programme.programme,
              reason_for_refusal:,
              recorded_by: current_user,
              response: consent_form_programme.response,
              route: "website",
              submitted_at: consent_form.recorded_at,
              vaccine_methods: consent_form_programme.vaccine_methods,
              academic_year: consent_form.academic_year
            )
          end

      StatusUpdater.call(patient:)

      consents
    end
  end

  REASON_FOR_REFUSAL_REQUIRES_NOTES = %w[
    other
    will_be_vaccinated_elsewhere
    medical_reasons
    already_vaccinated
  ].freeze

  def requires_notes?
    withdrawn? || invalidated? ||
      (
        response_refused? &&
          reason_for_refusal.in?(REASON_FOR_REFUSAL_REQUIRES_NOTES)
      )
  end

  def update_vaccination_records_no_notify!
    vaccination_records = VaccinationRecord.where(patient:, programme:)

    vaccination_records.find_each do |vaccination_record|
      vaccination_record.update!(
        notify_parents:
          VaccinationNotificationCriteria.call(vaccination_record:)
      )
    end
  end

  class ConsentFormNotRecorded < StandardError
  end
end
