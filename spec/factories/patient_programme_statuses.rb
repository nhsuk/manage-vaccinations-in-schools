# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_programme_statuses
#
#  id               :bigint           not null, primary key
#  academic_year    :integer          not null
#  date             :date
#  dose_sequence    :integer
#  programme_type   :enum             not null
#  status           :integer          default("not_eligible"), not null
#  vaccine_methods  :integer          is an Array
#  without_gelatine :boolean
#  patient_id       :bigint           not null
#
# Indexes
#
#  idx_on_academic_year_patient_id_3d5bf8d2c8                 (academic_year,patient_id)
#  idx_on_patient_id_academic_year_programme_type_75e0e0c471  (patient_id,academic_year,programme_type) UNIQUE
#  index_patient_programme_statuses_on_patient_id             (patient_id)
#  index_patient_programme_statuses_on_status                 (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :patient_programme_status, class: "Patient::ProgrammeStatus" do
    patient
    academic_year { AcademicYear.current }
    programme { Programme.sample }

    traits_for_enum :status

    trait :cannot_vaccinate_delay_vaccination do
      status { "cannot_vaccinate_delay_vaccination" }
      date { Date.tomorrow }
    end
  end
end
