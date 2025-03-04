# frozen_string_literal: true

describe Reports::SystmOneExporter do
  subject(:csv_row) { parsed_csv.first }

  before { vaccination_record }

  let(:csv) do
    described_class.call(
      organisation:,
      programme:,
      start_date: 1.month.ago.to_date,
      end_date: Date.current
    )
  end
  let(:programme) { create(:programme, :hpv, organisations: [organisation]) }
  let(:organisation) { create(:organisation, ods_code: "ABC123") }
  let(:location) { create(:school) }
  let(:session) do
    create(:session, organisation:, programmes: [programme], location:)
  end
  let(:patient) { create(:patient) }
  let(:vaccination_record) do
    create(
      :vaccination_record,
      programme:,
      patient:,
      session:,
      performed_at: 2.weeks.ago
    )
  end
  let(:parsed_csv) { CSV.parse(csv, headers: true) }

  it "includes the patient and vaccination details" do
    expect(parsed_csv.first.to_h).to eq(
      {
        "Practice code" => "ABC123",
        "NHS number" => vaccination_record.patient.nhs_number,
        "Surname" => vaccination_record.patient.family_name,
        "Middle name" => "",
        "Forename" => vaccination_record.patient.given_name,
        "Gender" => "U",
        "Date of Birth" =>
          vaccination_record.patient.date_of_birth.strftime("%d/%m/%Y"),
        "House name" => vaccination_record.patient.address_line_2,
        "House number and road" => vaccination_record.patient.address_line_1,
        "Town" => vaccination_record.patient.address_town,
        "Postcode" => vaccination_record.patient.address_postcode,
        "Vaccination" => "Y19a4",
        "Part" => "",
        "Admin date" =>
          vaccination_record.performed_at.to_date.strftime("%d/%m/%Y"),
        "Batch number" => vaccination_record.batch.name,
        "Expiry date" => vaccination_record.batch.expiry.strftime("%d/%m/%Y"),
        "Dose" => vaccination_record.dose_volume_ml.to_s,
        "Reason" => "Routine",
        "Site" => vaccination_record.delivery_site,
        "Method" => vaccination_record.delivery_method,
        "Notes" => vaccination_record.notes
      }
    )
  end

  context "no vaccination details" do
    before { vaccination_record.destroy }

    it { should be_blank }
  end

  context "with vaccination records outside the date range" do
    let(:vaccination_record) do
      create(
        :vaccination_record,
        programme:,
        patient:,
        session:,
        created_at: 2.months.ago,
        updated_at: 2.months.ago,
        performed_at: 2.months.ago
      )
    end

    it { should be_blank }
  end

  context "with vaccination records that haven't been administered" do
    let(:vaccination_record) do
      create(
        :vaccination_record,
        :not_administered,
        programme:,
        patient:,
        session:
      )
    end

    it { should be_blank }
  end

  context "with vaccination records updated within the date range do" do
    let(:vaccination_record) do
      create(
        :vaccination_record,
        programme:,
        patient:,
        session:,
        created_at: 2.months.ago,
        updated_at: 1.day.ago,
        performed_at: 2.months.ago
      )
    end

    it { should_not be_blank }
  end

  context "with a session in a different organisation" do
    let(:programme) do
      create(:programme, :hpv, organisations: [other_organisation])
    end
    let(:other_organisation) { create(:organisation, ods_code: "XYZ890") }

    let(:session) do
      create(
        :session,
        organisation: other_organisation,
        programmes: [programme],
        location:
      )
    end

    it { should be_blank }
  end

  describe "Gender field" do
    subject { csv_row["Gender"] }

    context "gender_code is male" do
      let(:patient) { create(:patient, gender_code: :male) }

      it { should eq "M" }
    end

    context "gender_code is female" do
      let(:patient) { create(:patient, gender_code: :female) }

      it { should eq "F" }
    end

    context "gender_code is not specified" do
      let(:patient) { create(:patient, gender_code: :not_specified) }

      it { should eq "U" }
    end
  end
end
