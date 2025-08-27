# frozen_string_literal: true

describe Reports::SystmOneExporter do
  subject(:csv_row) { parsed_csv.first }

  before { vaccination_record }

  around { |example| travel_to(Date.new(2025, 8, 31)) { example.run } }

  let(:csv) do
    described_class.call(
      team:,
      programme:,
      academic_year:,
      start_date: 1.month.ago.to_date,
      end_date: Date.current
    )
  end
  let(:programme) { create(:programme, :hpv) }
  let(:academic_year) { AcademicYear.current }
  let(:team) { create(:team, ods_code: "ABC123", programmes: [programme]) }
  let(:location) { create(:school) }
  let(:session) { create(:session, team:, programmes: [programme], location:) }
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
        "Practice code" => location.urn,
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
        "Site" => "Left deltoid",
        "Method" => "Intramuscular",
        "Notes" => "Administered by: USER, Test"
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

  context "with vaccination records for a different programme" do
    let(:other_programme) do
      create(
        :programme,
        type: (Programme.types.values - [programme.type]).sample
      )
    end

    let(:vaccination_record) do
      create(
        :vaccination_record,
        programme: other_programme,
        patient:,
        session:
      )
    end

    it { should be_blank }
  end

  context "with a session in a different team" do
    let(:other_team) do
      create(:team, ods_code: "XYZ890", programmes: [programme])
    end

    let(:session) do
      create(:session, team: other_team, programmes: [programme], location:)
    end

    it { should be_blank }
  end

  describe "Practice code field" do
    subject { csv_row["Practice code"] }

    context "location is a gp clinic" do
      let(:location) { create(:gp_practice, team:) }

      it { should eq(location.ods_code) }
    end

    context "location is a generic clinic" do
      let(:location) { create(:generic_clinic, team:) }

      it { should eq(location.ods_code) }
    end

    context "location has a SystmOne code" do
      let(:location) { create(:school, systm_one_code: "A1") }

      it { should eq("A1") }
    end
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

  describe "Vaccination field" do
    subject { csv_row["Vaccination"] }

    let(:vaccination_record) do
      create(
        :vaccination_record,
        programme:,
        patient:,
        session:,
        performed_at: 2.weeks.ago,
        vaccine:,
        dose_sequence:
      )
    end

    context "HPV Gardasil 9 dose 2" do
      let(:vaccine) { Vaccine.find_by(brand: "Gardasil 9") }
      let(:dose_sequence) { 2 }

      it { should eq "Y19a5" }
    end

    context "HPV Gardasil 9 dose 3" do
      let(:vaccine) { Vaccine.find_by(brand: "Gardasil 9") }
      let(:dose_sequence) { 3 }

      it { should eq "Y19a6" }
    end

    context "unknown vaccine and no dose sequence" do
      let(:vaccine) { create(:vaccine, :fluenz) }
      let(:dose_sequence) { 1 }

      it { should eq "Fluenz Part 1" }
    end
  end

  describe "Site field" do
    subject { csv_row["Site"] }

    let(:vaccination_record) do
      create(
        :vaccination_record,
        programme:,
        patient:,
        session:,
        performed_at: 2.weeks.ago,
        delivery_site:
      )
    end

    context "left arm lower position" do
      let(:delivery_site) { "left_arm_lower_position" }

      it { should eq "Left anterior forearm" }
    end
  end

  describe "address fields" do
    context "patient is restricted" do
      let(:patient) { create(:patient, :restricted) }

      it "does not include address details" do
        expect(csv_row.to_h).to include(
          "House name" => "",
          "House number and road" => "",
          "Town" => "",
          "Postcode" => ""
        )
      end
    end
  end

  describe "Notes field" do
    subject { csv_row["Notes"] }

    let(:nurse) { create(:nurse, given_name: "Nurse") }
    let(:healthcare_assistant) do
      create(:healthcare_assistant, given_name: "HCA")
    end

    context "nasal flu administered by healthcare assistant under PGD" do
      let(:vaccination_record) do
        create(
          :vaccination_record,
          programme:,
          patient:,
          session:,
          protocol: "pgd",
          performed_by: healthcare_assistant,
          supplied_by: nurse
        )
      end

      it { should eq("Administered by: USER, HCA\nAuthorised by: USER, Nurse") }
    end

    context "nasal flu administered by healthcare assistant under PSD" do
      let(:vaccination_record) do
        create(
          :vaccination_record,
          programme:,
          patient:,
          session:,
          protocol: "psd",
          performed_by: healthcare_assistant,
          supplied_by: nurse
        )
      end

      it { should eq("Administered by: USER, HCA\nPrescribed by: USER, Nurse") }
    end
  end

  describe "Flu vaccine records" do
    let(:vaccination_record) do
      create(
        :vaccination_record,
        programme:,
        patient:,
        session:,
        performed_at: 1.week.ago,
        vaccine:,
        dose_sequence: 1,
        delivery_method:,
        delivery_site:
      )
    end

    context "for flu nasal" do
      let(:programme) { create(:programme, :flu) }
      let(:vaccine) { Vaccine.find_by(brand: "Fluenz") }
      let(:delivery_method) { :nasal_spray }
      let(:delivery_site) { :nose }

      it "uses the generic SystmOne code" do
        expect(csv_row["Vaccination"]).to eq "Fluenz Part 1"
      end

      it "uses 'Nasal' as the method" do
        expect(csv_row["Method"]).to eq "Nasal"
      end

      it "uses 'Nasal' as the site" do
        expect(csv_row["Site"]).to eq "Nasal"
      end
    end

    context "for flu injection" do
      let(:programme) { create(:programme, :flu) }
      let(:vaccine) do
        Vaccine.find_by(brand: "Cell-based Trivalent Influenza Vaccine Seqirus")
      end
      let(:delivery_method) { :intramuscular }
      let(:delivery_site) { :right_arm_upper_position }

      it "uses the generic SystmOne code" do
        expect(
          csv_row["Vaccination"]
        ).to eq "Cell-based Trivalent Influenza Vaccine Seqirus Part 1"
      end

      it "uses 'Intramuscular' as the method" do
        expect(csv_row["Method"]).to eq "Intramuscular"
      end

      it "uses 'Right deltoid' as the site" do
        expect(csv_row["Site"]).to eq "Right deltoid"
      end
    end
  end
end
