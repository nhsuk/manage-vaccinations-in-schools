# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_vaccination_statuses
#
#  id                    :bigint           not null, primary key
#  academic_year         :integer          not null
#  latest_session_status :integer          default("none_yet"), not null
#  status                :integer          default("none_yet"), not null
#  patient_id            :bigint           not null
#  programme_id          :bigint           not null
#
# Indexes
#
#  idx_on_patient_id_programme_id_academic_year_fc0b47b743  (patient_id,programme_id,academic_year) UNIQUE
#  index_patient_vaccination_statuses_on_status             (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id)
#
class Patient::VaccinationStatus < ApplicationRecord
  belongs_to :patient
  belongs_to :programme

  has_many :consents,
           -> { not_invalidated.response_provided.includes(:parent, :patient) },
           through: :patient

  has_many :triages,
           -> { not_invalidated.order(created_at: :desc) },
           through: :patient

  has_many :vaccination_records,
           -> { kept.order(performed_at: :desc) },
           through: :patient

  has_one :patient_session

  has_one :session_attendance,
          -> { today },
          through: :patient,
          source: :session_attendances

  enum :status,
       { none_yet: 0, vaccinated: 1, could_not_vaccinate: 2 },
       default: :none_yet,
       validate: true

  enum :latest_session_status,
       PatientSession::SessionStatus.statuses,
       default: :none_yet,
       prefix: true,
       validate: true

  def assign_status
    self.status = generator.status
    self.latest_session_status = session_generator&.status || :none_yet
  end

  private

  def generator
    @generator ||=
      StatusGenerator::Vaccination.new(
        programme:,
        academic_year:,
        patient:,
        consents:,
        triages:,
        vaccination_records:
      )
  end

  def session_generator
    @session_generator ||=
      if (session_id = vaccination_records.first&.session_id)
        StatusGenerator::Session.new(
          session_id:,
          academic_year:,
          session_attendance:,
          programme_id:,
          consents:,
          triages:,
          vaccination_records:
        )
      end
  end
end
