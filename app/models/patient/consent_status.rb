# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_consent_statuses
#
#  id              :bigint           not null, primary key
#  status          :integer          default("no_response"), not null
#  vaccine_methods :integer          default([]), not null, is an Array
#  patient_id      :bigint           not null
#  programme_id    :bigint           not null
#
# Indexes
#
#  index_patient_consent_statuses_on_patient_id_and_programme_id  (patient_id,programme_id) UNIQUE
#  index_patient_consent_statuses_on_status                       (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id)
#
class Patient::ConsentStatus < ApplicationRecord
  include HasVaccineMethods

  belongs_to :patient
  belongs_to :programme

  has_many :consents,
           -> { not_invalidated.response_provided.includes(:parent, :patient) },
           through: :patient

  scope :has_vaccine_method,
        ->(vaccine_method) do
          where("vaccine_methods[1] = ?", vaccine_methods.fetch(vaccine_method))
        end

  enum :status,
       { no_response: 0, given: 1, refused: 2, conflicts: 3 },
       default: :no_response,
       validate: true

  validates :vaccine_methods, presence: true, if: :given?

  def assign_status
    self.status =
      if status_should_be_given?
        :given
      elsif status_should_be_refused?
        :refused
      elsif status_should_be_conflicts?
        :conflicts
      else
        :no_response
      end

    self.vaccine_methods = (agreed_vaccine_methods if status_should_be_given?)
  end

  def vaccine_method_nasal? = vaccine_methods.include?("nasal")

  private

  def status_should_be_given?
    consents_for_status.any? && consents_for_status.all?(&:response_given?) &&
      agreed_vaccine_methods.present?
  end

  def status_should_be_refused?
    latest_consents.any? && latest_consents.all?(&:response_refused?)
  end

  def status_should_be_conflicts?
    consents_for_status =
      (self_consents.any? ? self_consents : parental_consents)

    if consents_for_status.any?(&:response_refused?) &&
         consents_for_status.any?(&:response_given?)
      return true
    end

    consents_for_status.any? && consents_for_status.all?(&:response_given?) &&
      agreed_vaccine_methods.blank?
  end

  def agreed_vaccine_methods
    @agreed_vaccine_methods ||=
      consents_for_status.map(&:vaccine_methods).inject(&:intersection)
  end

  def consents_for_status
    @consents_for_status ||=
      self_consents.any? ? self_consents : parental_consents
  end

  def self_consents
    @self_consents ||= latest_consents.select(&:via_self_consent?)
  end

  def parental_consents
    @parental_consents ||= latest_consents.reject(&:via_self_consent?)
  end

  def latest_consents
    @latest_consents ||= ConsentGrouper.call(consents, programme_id:)
  end
end
