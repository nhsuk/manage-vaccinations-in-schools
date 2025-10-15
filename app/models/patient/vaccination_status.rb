# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_vaccination_statuses
#
#  id                    :bigint           not null, primary key
#  academic_year         :integer          not null
#  latest_date           :date
#  latest_session_status :integer
#  status                :integer          default("not_eligible"), not null
#  latest_location_id    :bigint
#  patient_id            :bigint           not null
#  programme_id          :bigint           not null
#
# Indexes
#
#  idx_on_patient_id_programme_id_academic_year_fc0b47b743   (patient_id,programme_id,academic_year) UNIQUE
#  index_patient_vaccination_statuses_on_latest_location_id  (latest_location_id)
#  index_patient_vaccination_statuses_on_status              (status)
#
# Foreign Keys
#
#  fk_rails_...  (latest_location_id => locations.id)
#  fk_rails_...  (patient_id => patients.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id)
#
class Patient::VaccinationStatus < ApplicationRecord
  self.ignored_columns = %i[status_changed_at]

  belongs_to :patient
  belongs_to :programme

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
    self.latest_date = session_generator.date
    self.latest_location_id = generator.location_id
    self.latest_session_status = session_generator.status
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
        vaccination_records:
      )
  end

  def session_generator
    @session_generator ||=
      StatusGenerator::Session.new(
        session_id:,
        academic_year:,
        attendance_record:,
        programme:,
        patient:,
        consents:,
        triages:,
        vaccination_records:
      )
  end

  def latest_vaccination_record
    @latest_vaccination_record ||=
      vaccination_records.reverse.find do
        it.programme_id == programme.id &&
          if programme.seasonal?
            it.academic_year == academic_year
          else
            it.academic_year <= academic_year
          end
      end
  end

  delegate :session_id, to: :latest_vaccination_record, allow_nil: true
end
