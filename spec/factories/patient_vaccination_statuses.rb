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
#  programme_id          :bigint
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
FactoryBot.define do
  factory :patient_vaccination_status, class: "Patient::VaccinationStatus" do
    patient
    programme { CachedProgramme.sample }
    academic_year { AcademicYear.current }

    traits_for_enum :status

    trait :vaccinated do
      status { "vaccinated" }
      latest_date { Date.current }
    end
  end
end
