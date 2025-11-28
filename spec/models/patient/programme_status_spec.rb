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
describe Patient::ProgrammeStatus do
  subject(:patient_programme_status) { build(:patient_programme_status) }

  describe "associations" do
    it { should belong_to(:patient) }
  end

  describe "#assign" do
    subject(:assign) { patient_programme_status.assign }

    let(:programme_generator) { instance_double(StatusGenerator::Programme) }

    before do
      allow(StatusGenerator::Programme).to receive(:new).and_return(
        programme_generator
      )
      allow(programme_generator).to receive_messages(
        date: Date.new(2020, 1, 1),
        dose_sequence: 1,
        status: "vaccinated",
        vaccine_methods: %w[injection],
        without_gelatine: true
      )
    end

    it "calls the status generator" do
      assign

      expect(patient_programme_status.date).to eq(Date.new(2020, 1, 1))
      expect(patient_programme_status.dose_sequence).to eq(1)
      expect(patient_programme_status.status).to eq("vaccinated")
      expect(patient_programme_status.vaccine_methods).to eq(%w[injection])
      expect(patient_programme_status.without_gelatine).to be(true)
    end
  end
end
