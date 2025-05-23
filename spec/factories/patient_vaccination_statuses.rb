# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_vaccination_statuses
#
#  id           :bigint           not null, primary key
#  status       :integer          default("none_yet"), not null
#  patient_id   :bigint           not null
#  programme_id :bigint           not null
#
# Indexes
#
#  idx_on_patient_id_programme_id_e876faade2     (patient_id,programme_id) UNIQUE
#  index_patient_vaccination_statuses_on_status  (status)
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

    traits_for_enum :status
  end
end
