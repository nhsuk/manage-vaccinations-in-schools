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
describe Patient::VaccinationStatus do
  subject(:patient_vaccination_status) do
    build(:patient_vaccination_status, patient:, programme:)
  end

  let(:patient) { create(:patient, programmes: [programme]) }
  let(:programme) { CachedProgramme.sample }

  it { should belong_to(:patient) }
  it { should belong_to(:programme) }

  it do
    expect(patient_vaccination_status).to define_enum_for(:status).with_values(
      %i[not_eligible eligible due vaccinated]
    )
  end

  describe "#assign_status" do
    subject(:assign_status) { patient_vaccination_status.assign_status }

    let(:vaccination_generator) do
      instance_double(StatusGenerator::Vaccination)
    end

    before do
      allow(StatusGenerator::Vaccination).to receive(:new).and_return(
        vaccination_generator
      )
      allow(vaccination_generator).to receive_messages(
        dose_sequence: 1,
        latest_date: Date.new(2020, 1, 1),
        latest_location_id: 999,
        latest_session_status: "unwell",
        status: "vaccinated"
      )
    end

    it "calls the status generators" do
      assign_status

      expect(patient_vaccination_status.dose_sequence).to eq(1)
      expect(patient_vaccination_status.latest_date).to eq(Date.new(2020, 1, 1))
      expect(patient_vaccination_status.latest_location_id).to eq(999)
      expect(patient_vaccination_status.latest_session_status).to eq("unwell")
      expect(patient_vaccination_status.status).to eq("vaccinated")
    end
  end
end
