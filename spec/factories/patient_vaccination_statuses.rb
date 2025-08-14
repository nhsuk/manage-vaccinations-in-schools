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
FactoryBot.define do
  factory :patient_vaccination_status, class: "Patient::VaccinationStatus" do
    patient
    programme
    academic_year { Date.current.academic_year }
    status_changed_at { academic_year.to_academic_year_date_range.begin }

    traits_for_enum :status
  end
end
