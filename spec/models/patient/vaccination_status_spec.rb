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
describe Patient::VaccinationStatus do
  subject(:patient_vaccination_status) do
    build(:patient_vaccination_status, patient:, programme:)
  end

  let(:patient) { create(:patient, programmes: [programme]) }
  let(:programme) { create(:programme) }

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
    let(:session_generator) { instance_double(StatusGenerator::Session) }

    before do
      allow(StatusGenerator::Vaccination).to receive(:new).and_return(
        vaccination_generator
      )
      allow(StatusGenerator::Session).to receive(:new).and_return(
        session_generator
      )
      allow(vaccination_generator).to receive_messages(
        status: :vaccinated,
        location_id: 999
      )
      allow(session_generator).to receive_messages(
        status: :attending,
        date: Date.new(2020, 1, 1)
      )
    end

    it "calls the status generators" do
      assign_status

      expect(patient_vaccination_status.status).to eq("vaccinated")
      expect(patient_vaccination_status.latest_location_id).to eq(999)
      expect(patient_vaccination_status.latest_session_status).to eq(:attending)
      expect(patient_vaccination_status.latest_date).to eq(Date.new(2020, 1, 1))
    end
  end
end
