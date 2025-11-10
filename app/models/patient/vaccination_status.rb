# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_vaccination_statuses
#
#  id                    :bigint           not null, primary key
#  academic_year         :integer          not null
#  dose_sequence         :integer
#  latest_date           :date
#  latest_session_status :integer
#  programme_type        :enum             not null
#  status                :integer          default("not_eligible"), not null
#  latest_location_id    :bigint
#  patient_id            :bigint           not null
#  programme_id          :bigint           not null
#
# Indexes
#
#  idx_on_academic_year_patient_id_9c400fc863                 (academic_year,patient_id)
#  idx_on_patient_id_programme_type_academic_year_962639d2ac  (patient_id,programme_type,academic_year) UNIQUE
#  index_patient_vaccination_statuses_on_latest_location_id   (latest_location_id)
#  index_patient_vaccination_statuses_on_status               (status)
#
# Foreign Keys
#
#  fk_rails_...  (latest_location_id => locations.id)
#  fk_rails_...  (patient_id => patients.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id)
#
class Patient::VaccinationStatus < ApplicationRecord
  include BelongsToProgramme

  belongs_to :patient

  belongs_to :latest_location, class_name: "Location", optional: true

  has_many :patient_locations,
           -> { includes(location: :location_programme_year_groups) },
           through: :patient

  has_many :consents,
           -> { not_invalidated.response_provided.includes(:parent, :patient) },
           through: :patient

  has_many :triages,
           -> { not_invalidated.order(created_at: :desc) },
           through: :patient

  has_many :vaccination_records,
           -> { kept.order(performed_at: :desc) },
           through: :patient

  has_one :attendance_record,
          -> { today },
          through: :patient,
          source: :attendance_records

  enum :status,
       { not_eligible: 0, eligible: 1, due: 2, vaccinated: 3 },
       default: :not_eligible,
       validate: true

  enum :latest_session_status,
       { refused: 0, absent: 1, unwell: 2, contraindicated: 3, already_had: 4 },
       prefix: true,
       validate: {
         allow_nil: true
       }

  def assign_status
    self.status = generator.status
    self.dose_sequence = generator.dose_sequence
    self.latest_date = generator.latest_date
    self.latest_location_id = generator.latest_location_id
    self.latest_session_status = generator.latest_session_status
  end

  private

  def generator
    @generator ||=
      StatusGenerator::Vaccination.new(
        programme:,
        academic_year:,
        patient:,
        patient_locations:,
        consents:,
        triages:,
        attendance_record:,
        vaccination_records:
      )
  end
end
