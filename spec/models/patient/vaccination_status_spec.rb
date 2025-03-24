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
describe Patient::VaccinationStatus do
  subject(:patient_vaccination_status) do
    build(:patient_vaccination_status, patient:, programme:)
  end

  let(:patient) { create(:patient) }
  let(:programme) { create(:programme) }

  it { should belong_to(:patient) }
  it { should belong_to(:programme) }

  it do
    expect(patient_vaccination_status).to define_enum_for(:status).with_values(
      %i[none_yet vaccinated could_not_vaccinate]
    )
  end
end
