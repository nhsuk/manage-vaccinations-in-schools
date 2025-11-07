# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_consent_statuses
#
#  id               :bigint           not null, primary key
#  academic_year    :integer          not null
#  programme_type   :enum             not null
#  status           :integer          default("no_response"), not null
#  vaccine_methods  :integer          default([]), not null, is an Array
#  without_gelatine :boolean
#  patient_id       :bigint           not null
#  programme_id     :bigint           not null
#
# Indexes
#
#  idx_on_patient_id_programme_id_academic_year_1d3170e398         (patient_id,programme_id,academic_year) UNIQUE
#  idx_on_patient_id_programme_type_academic_year_89a70c9513       (patient_id,programme_type,academic_year) UNIQUE
#  index_patient_consent_statuses_on_academic_year_and_patient_id  (academic_year,patient_id)
#  index_patient_consent_statuses_on_status                        (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id)
#
class Patient::ConsentStatus < ApplicationRecord
  include BelongsToProgramme
  include HasVaccineMethods

  belongs_to :patient

  has_many :consents,
           -> { not_invalidated.response_provided.includes(:parent, :patient) },
           through: :patient

  has_many :vaccination_records,
           -> { kept.order(performed_at: :desc) },
           through: :patient

  scope :has_vaccine_method,
        ->(vaccine_method) do
          where(
            "vaccine_methods[1] IN (?)",
            Array(vaccine_method).map { vaccine_methods.fetch(it) }
          )
        end

  enum :status,
       { no_response: 0, given: 1, refused: 2, conflicts: 3, not_required: 4 },
       default: :no_response,
       validate: true

  validates :vaccine_methods, presence: true, if: :given?

  def assign_status
    self.status = generator.status
    self.vaccine_methods = generator.vaccine_methods
    self.without_gelatine = generator.without_gelatine
  end

  def vaccine_method_nasal? = vaccine_methods.include?("nasal")

  private

  def generator
    @generator ||=
      StatusGenerator::Consent.new(
        programme:,
        academic_year:,
        patient:,
        consents:,
        vaccination_records:
      )
  end
end
