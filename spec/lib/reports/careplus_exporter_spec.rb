# frozen_string_literal: true

describe Reports::CareplusExporter do
  subject(:csv) do
    described_class.call(
      organisation:,
      programme: programmes.first,
      start_date: 1.month.ago.to_date,
      end_date: Date.current
    )
  end

  let(:programmes) { [create(:programme, :hpv)] }
  let(:organisation) do
    create(:organisation, careplus_venue_code: "ABC", programmes:)
  end
  let(:location) do
    create(
      :school,
      gias_local_authority_code: 123,
      gias_establishment_number: 456
    )
  end
  let(:session) { create(:session, organisation:, programmes:, location:) }
  let(:parsed_csv) { CSV.parse(csv) }
  let(:headers) { parsed_csv.first }
  let(:data_rows) { parsed_csv[1..] }

  it "includes the expected headers" do
    expect(headers).to include(
      "NHS Number",
      "Surname",
      "Forename",
      "Date of Birth",
      "Address Line 1",
      "Person Giving Consent",
      "Ethnicity",
      "Date Attended",
      "Time Attended",
      "Venue Type",
      "Venue Code",
      "Staff Type",
      "Staff Code",
      "Attended",
      "Reason Not Attended",
      "Suspension End Date"
    )

    (1..5).each do |i|
      expect(headers).to include(
        "Vaccine #{i}",
        "Dose #{i}",
        "Reason Not Given #{i}",
        "Site #{i}",
        "Manufacturer #{i}",
        "Batch No #{i}"
      )
    end
  end

  it "does not include the patient if they have no vaccination details" do
    create(:patient_session, session:)

    expect(data_rows.first).to be_nil
  end

  it "includes the patient and vaccination details" do
    patient_session =
      create(
        :patient_session,
        :consent_given_triage_not_needed,
        programmes:,
        session:
      )
    vaccination_record =
      create(
        :vaccination_record,
        programme: programmes.first,
        patient: patient_session.patient,
        session: patient_session.session,
        performed_at: 2.weeks.ago
      )

    attended_index = headers.index("Attended")
    vaccine_index = headers.index("Vaccine 1")
    batch_index = headers.index("Batch No 1")
    site_index = headers.index("Site 1")
    staff_type_index = headers.index("Staff Type")
    staff_code_index = headers.index("Staff Code")
    venue_type_index = headers.index("Venue Type")
    venue_code_index = headers.index("Venue Code")

    row = data_rows.first

    expect(row[attended_index]).to eq("Y")
    expect(row[vaccine_index]).to eq(
      vaccination_record.vaccine.snomed_product_code
    )
    expect(row[batch_index]).to eq(vaccination_record.batch.name)
    expect(row[site_index]).to eq("ULA")
    expect(row[staff_type_index]).to eq("IN")
    expect(row[staff_code_index]).to eq("LW5PM")
    expect(row[venue_type_index]).to eq("SC")
    expect(row[venue_code_index]).to eq("123456")
  end

  context "in a community clinic" do
    let(:location) { create(:generic_clinic, organisation:) }

    it "includes clinic location details" do
      patient = create(:patient, year_group: 8)
      create(
        :patient_session,
        :consent_given_triage_not_needed,
        programmes:,
        patient:,
        session:
      )
      create(
        :vaccination_record,
        programme: programmes.first,
        patient:,
        session:,
        location_name: "A clinic"
      )

      venue_type_index = headers.index("Venue Type")
      venue_code_index = headers.index("Venue Code")

      row = data_rows.first

      expect(row[venue_type_index]).to eq("CL")
      expect(row[venue_code_index]).to eq("ABC")
    end
  end

  it "excludes vaccination records outside the date range" do
    patient = create(:patient_session, session:).patient

    create(
      :vaccination_record,
      programme: programmes.first,
      patient:,
      session:,
      created_at: 2.months.ago,
      updated_at: 2.months.ago,
      performed_at: 2.months.ago
    )

    expect(data_rows.first).to be_nil
  end

  it "excludes not administered vaccination records" do
    patient = create(:patient_session, session:).patient

    create(
      :vaccination_record,
      :not_administered,
      programme: programmes.first,
      patient:,
      session:
    )

    expect(data_rows.first).to be_nil
  end

  it "includes vaccination records updated within the date range" do
    patient = create(:patient_session, session:).patient

    create(
      :vaccination_record,
      programme: programmes.first,
      patient:,
      session:,
      created_at: 2.months.ago,
      updated_at: 1.day.ago,
      performed_at: 2.months.ago
    )

    expect(data_rows.first).not_to be_nil
  end

  context "with a session in a different organisation" do
    let(:session) { create(:session, programmes:, location:) }

    it "excludes the vaccination record" do
      create(:vaccination_record, programme: programmes.first, session:)

      expect(data_rows.first).to be_nil
    end
  end
end
