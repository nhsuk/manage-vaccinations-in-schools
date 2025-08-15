# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_vaccination_statuses
#
#  id                    :bigint           not null, primary key
#  academic_year         :integer          not null
#  latest_session_status :integer          default("none_yet"), not null
#  status                :integer          default("none_yet"), not null
#  status_changed_at     :datetime         not null
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
       {
         none_yet: 0,
         vaccinated: 1,
         already_had: 2,
         had_contraindications: 3,
         refused: 4,
         absent_from_session: 5,
         unwell: 6,
         conflicting_consent: 7
       },
       default: :none_yet,
       prefix: true,
       validate: true

  def assign_status
    self.status = generator.status
    self.latest_session_status = session_generator&.status || :none_yet
    self.status_changed_at =
      session_generator&.status_changed_at ||
        academic_year.to_academic_year_date_range.begin
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
      StatusGenerator::Session.new(
        session_id:,
        academic_year:,
        session_attendance:,
        programme:,
        patient:,
        consents:,
        triages:,
        vaccination_records:
      )
  end

  def latest_vaccination_record
    @latest_vaccination_record ||=
      vaccination_records.find do
        it.academic_year == academic_year && it.programme_id == programme_id
      end
  end

  delegate :session_id, to: :latest_vaccination_record, allow_nil: true
end
