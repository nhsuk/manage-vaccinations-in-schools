# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_consent_statuses
#
#  id                               :bigint           not null, primary key
#  health_answers_require_follow_up :boolean          default(FALSE), not null
#  status                           :integer          default("no_response"), not null
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  patient_id                       :bigint           not null
#  programme_id                     :bigint           not null
#
# Indexes
#
#  index_patient_consent_statuses_on_patient_id                   (patient_id)
#  index_patient_consent_statuses_on_patient_id_and_programme_id  (patient_id,programme_id) UNIQUE
#  index_patient_consent_statuses_on_programme_id                 (programme_id)
#  index_patient_consent_statuses_on_status                       (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id)
#
class Patient::ConsentStatus < ApplicationRecord
  belongs_to :patient
  belongs_to :programme

  enum :status,
       { no_response: 0, given: 1, refused: 2, conflicts: 3 },
       validate: true

  def refresh!
    health_answers_require_follow_up =
      latest_consents.any?(&:health_answers_require_follow_up?)

    if status_should_be_given?
      update!(status: :given, health_answers_require_follow_up:)
    elsif status_should_be_refused?
      update!(status: :refused, health_answers_require_follow_up:)
    elsif status_should_be_conflicts?
      update!(status: :conflicts, health_answers_require_follow_up:)
    else
      update!(status: :no_response, health_answers_require_follow_up:)
    end
  end

  private

  def status_should_be_given?
    if self_consents.any?
      self_consents.all?(&:response_given?)
    else
      parental_consents.any? && parental_consents.all?(&:response_given?)
    end
  end

  def status_should_be_refused?
    latest_consents.any? && latest_consents.all?(&:response_refused?)
  end

  def status_should_be_conflicts?
    if self_consents.any?
      self_consents.any?(&:response_refused?) &&
        self_consents.any?(&:response_given?)
    else
      parental_consents.any?(&:response_refused?) &&
        parental_consents.any?(&:response_given?)
    end
  end

  def self_consents
    @self_consents ||= latest_consents.select(&:via_self_consent?)
  end

  def parental_consents
    @parental_consents ||= latest_consents.reject(&:via_self_consent?)
  end

  def latest_consents
    @latest_consents ||= patient.latest_consents(programme_id:)
  end
end
