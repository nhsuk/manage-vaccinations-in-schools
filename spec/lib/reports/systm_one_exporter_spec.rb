# frozen_string_literal: true

describe Reports::SystmOneExporter do
  subject(:parsed_csv) { CSV.parse(csv, headers: true) }

  let(:csv) do
    described_class.call(
      organisation:,
      programme:,
      start_date: 1.month.ago.to_date,
      end_date: Date.current
    )
  end
  let(:programme) { create(:programme, :hpv) }
  let(:organisation) do
    create(:organisation, ods_code: "ABC123", programmes: [programme])
  end
  let(:location) { create(:school) }
  let(:session) { create(:session, organisation:, programme:, location:) }
  let(:headers) { parsed_csv.headers }

  it "includes the patient and vaccination details" do
    patient_session = create(:patient_session, session:)
    vaccination_record =
      create(
        :vaccination_record,
        programme:,
        patient_session:,
        performed_at: 2.weeks.ago
      )

    expect(parsed_csv.first.to_h).to eq(
      {
        "Practice code" => "ABC123",
        "NHS number" => vaccination_record.patient.nhs_number,
        "Surname" => vaccination_record.patient.family_name,
        "Middle name" => "",
        "Forename" => vaccination_record.patient.given_name,
        "Gender" => "Not known",
        "Date of Birth" =>
          vaccination_record.patient.date_of_birth.strftime("%d/%m/%Y"),
        "House name" => vaccination_record.patient.address_line_1,
        "House number and road" => vaccination_record.patient.address_line_2,
        "Town" => vaccination_record.patient.address_town,
        "Vaccination" => vaccination_record.vaccine.nivs_name,
        "Part" => vaccination_record.dose_sequence.to_s,
        "Admin date" => vaccination_record.performed_at.strftime("%d/%m/%Y"),
        "Batch number" => vaccination_record.batch.name,
        "Expiry date" => vaccination_record.batch.expiry.strftime("%d/%m/%Y"),
        "Dose" => vaccination_record.dose_volume_ml.to_s,
        "Reason" => "",
        "Site" => vaccination_record.delivery_site,
        "Method" => vaccination_record.delivery_method,
        "Notes" => vaccination_record.notes
      }
    )
  end

  context "no vaccination details" do
    before { create(:patient_session, session:) }

    it { should be_empty }
  end

  context "with vaccination records outside the date range" do
    before do
      patient_session = create(:patient_session, session:)
      create(
        :vaccination_record,
        programme:,
        patient_session:,
        created_at: 2.months.ago,
        updated_at: 2.months.ago,
        performed_at: 2.months.ago
      )
    end

    it { should be_empty }
  end

  context "with vaccination records that haven't been administered" do
    before do
      patient_session = create(:patient_session, session:)
      create(
        :vaccination_record,
        :not_administered,
        programme:,
        patient_session:
      )
    end

    it { should be_empty }
  end

  context "with vaccination records updated within the date range do" do
    before do
      patient_session = create(:patient_session, session:)
      create(
        :vaccination_record,
        programme:,
        patient_session:,
        created_at: 2.months.ago,
        updated_at: 1.day.ago,
        performed_at: 2.months.ago
      )
    end

    it { should_not be_empty }
  end

  context "with a session in a different organisation" do
    before do
      session = create(:session, programme:, location:)
      patient_session = create(:patient_session, session:)
      create(:vaccination_record, programme:, patient_session:)
    end

    it { should be_empty }
  end
end
