# frozen_string_literal: true

describe SessionXlsxExporter do
  def worksheet_to_hashes(worksheet)
    headers = worksheet[0].cells.map(&:value)
    rows =
      (1..worksheet.count - 1).map do |row_num|
        row = worksheet[row_num]
        next if row.nil?
        headers.zip(row.cells.map { |c| c&.value }).to_h
      end
    rows.compact
  end

  subject(:call) { described_class.call(session) }

  let(:programme) { create(:programme, :hpv) }
  let(:organisation) { create(:organisation, programmes: [programme]) }
  let(:user) do
    create(:user, email: "nurse@example.com", organisations: [organisation])
  end
  let(:team) { create(:team, organisation:) }
  let(:session) { create(:session, location:, organisation:, programme:) }

  context "a school session" do
    let(:location) { create(:location, :school, team:) }

    it { should_not be_blank }

    describe "headers" do
      subject(:headers) do
        workbook = RubyXL::Parser.parse_buffer(call)
        sheet = workbook.worksheets[0]
        sheet[0].cells.map(&:value)
      end

      it do
        expect(headers).to eq(
          %w[
            ORGANISATION_CODE
            SCHOOL_URN
            SCHOOL_NAME
            CARE_SETTING
            NHS_NUMBER
            PERSON_FORENAME
            PERSON_SURNAME
            PERSON_GENDER_CODE
            PERSON_DOB
            PERSON_POSTCODE
            DATE_OF_VACCINATION
            TIME_OF_VACCINATION
            VACCINATED
            VACCINE_GIVEN
            REASON_NOT_VACCINATED
            BATCH_NUMBER
            BATCH_EXPIRY_DATE
            ANATOMICAL_SITE
            DOSE_SEQUENCE
            PERFORMING_PROFESSIONAL_EMAIL
          ]
        )
      end
    end

    describe "rows" do
      subject(:rows) do
        workbook = RubyXL::Parser.parse_buffer(call)
        worksheet_to_hashes(workbook.worksheets[0])
      end

      let(:administered_at) { Time.zone.local(2024, 1, 1, 12, 0o5, 20) }
      let(:batch) { create(:batch, vaccine: programme.vaccines.active.first) }
      let(:patient_session) { create(:patient_session, patient:, session:) }
      let(:patient) { create(:patient) }

      it { should be_empty }

      context "with a patient without an outcome" do
        let!(:patient) { create(:patient, session:) }

        it "adds a row to fill in" do
          expect(rows.count).to eq(1)
          expect(rows.first.except("PERSON_DOB")).to eq(
            {
              "ANATOMICAL_SITE" => "",
              "BATCH_EXPIRY_DATE" => nil,
              "BATCH_NUMBER" => "",
              "CARE_SETTING" => 1,
              "DATE_OF_VACCINATION" => nil,
              "DOSE_SEQUENCE" => 1,
              "NHS_NUMBER" => patient.nhs_number.to_i,
              "ORGANISATION_CODE" => organisation.ods_code,
              "PERFORMING_PROFESSIONAL_EMAIL" => "",
              "PERSON_FORENAME" => patient.given_name,
              "PERSON_GENDER_CODE" => "Not known",
              "PERSON_POSTCODE" => patient.address_postcode,
              "PERSON_SURNAME" => patient.family_name,
              "SCHOOL_NAME" => location.name,
              "SCHOOL_URN" => location.urn.to_i,
              "TIME_OF_VACCINATION" => "",
              "VACCINATED" => "",
              "VACCINE_GIVEN" => "",
              "REASON_NOT_VACCINATED" => ""
            }
          )
          expect(rows.first["PERSON_DOB"].to_date).to eq(patient.date_of_birth)
        end
      end

      context "with a vaccinated patient" do
        before do
          create(
            :vaccination_record,
            administered_at:,
            batch:,
            patient_session:,
            programme:,
            performed_by: user
          )
        end

        it "adds a row with the vaccination details" do
          expect(rows.count).to eq(1)
          expect(rows.first.except("PERSON_DOB", "DATE_OF_VACCINATION")).to eq(
            {
              "ANATOMICAL_SITE" => "left upper arm",
              "BATCH_EXPIRY_DATE" => batch.expiry,
              "BATCH_NUMBER" => batch.name,
              "CARE_SETTING" => 1,
              "DOSE_SEQUENCE" => 1,
              "NHS_NUMBER" => patient.nhs_number.to_i,
              "ORGANISATION_CODE" => organisation.ods_code,
              "PERFORMING_PROFESSIONAL_EMAIL" => "nurse@example.com",
              "PERSON_FORENAME" => patient.given_name,
              "PERSON_GENDER_CODE" => "Not known",
              "PERSON_POSTCODE" => patient.address_postcode,
              "PERSON_SURNAME" => patient.family_name,
              "SCHOOL_NAME" => location.name,
              "SCHOOL_URN" => location.urn.to_i,
              "TIME_OF_VACCINATION" => "12:05:20",
              "VACCINATED" => "Y",
              "VACCINE_GIVEN" => "Gardasil9",
              "REASON_NOT_VACCINATED" => ""
            }
          )
          expect(rows.first["PERSON_DOB"].to_date).to eq(patient.date_of_birth)
          expect(rows.first["DATE_OF_VACCINATION"].to_date).to eq(
            administered_at.to_date
          )
        end
      end

      context "with a patient who couldn't be vaccinated" do
        before do
          create(
            :vaccination_record,
            :not_administered,
            patient_session:,
            programme:,
            performed_by: user
          )
        end

        it "adds a row to fill in" do
          expect(rows.count).to eq(1)
          expect(rows.first.except("PERSON_DOB")).to eq(
            {
              "ANATOMICAL_SITE" => nil,
              "BATCH_EXPIRY_DATE" => nil,
              "BATCH_NUMBER" => "",
              "CARE_SETTING" => 1,
              "DOSE_SEQUENCE" => "",
              "NHS_NUMBER" => patient.nhs_number.to_i,
              "ORGANISATION_CODE" => organisation.ods_code,
              "PERFORMING_PROFESSIONAL_EMAIL" => "nurse@example.com",
              "PERSON_FORENAME" => patient.given_name,
              "PERSON_GENDER_CODE" => "Not known",
              "PERSON_POSTCODE" => patient.address_postcode,
              "PERSON_SURNAME" => patient.family_name,
              "SCHOOL_NAME" => location.name,
              "SCHOOL_URN" => location.urn.to_i,
              "DATE_OF_VACCINATION" => nil,
              "TIME_OF_VACCINATION" => nil,
              "VACCINATED" => "N",
              "VACCINE_GIVEN" => "",
              "REASON_NOT_VACCINATED" => "unwell"
            }
          )
          expect(rows.first["PERSON_DOB"].to_date).to eq(patient.date_of_birth)
        end
      end
    end
  end

  context "a clinic session" do
    let(:location) { create(:location, :generic_clinic, team:) }

    it { should_not be_blank }

    describe "headers" do
      subject(:headers) do
        workbook = RubyXL::Parser.parse_buffer(call)
        sheet = workbook.worksheets[0]
        sheet[0].cells.map(&:value)
      end

      it do
        expect(headers).to eq(
          %w[
            ORGANISATION_CODE
            SCHOOL_URN
            SCHOOL_NAME
            CARE_SETTING
            NHS_NUMBER
            PERSON_FORENAME
            PERSON_SURNAME
            PERSON_GENDER_CODE
            PERSON_DOB
            PERSON_POSTCODE
            DATE_OF_VACCINATION
            TIME_OF_VACCINATION
            VACCINATED
            VACCINE_GIVEN
            REASON_NOT_VACCINATED
            BATCH_NUMBER
            BATCH_EXPIRY_DATE
            ANATOMICAL_SITE
            DOSE_SEQUENCE
            PERFORMING_PROFESSIONAL_EMAIL
            CLINIC_NAME
          ]
        )
      end
    end

    describe "rows" do
      subject(:rows) do
        workbook = RubyXL::Parser.parse_buffer(call)
        worksheet_to_hashes(workbook.worksheets[0])
      end

      it { should be_empty }

      context "with a patient without an outcome" do
        let!(:patient) { create(:patient, session:) }

        it "adds a row to fill in" do
          expect(rows.count).to eq(1)
          expect(rows.first.except("PERSON_DOB")).to eq(
            {
              "ANATOMICAL_SITE" => "",
              "BATCH_EXPIRY_DATE" => nil,
              "BATCH_NUMBER" => "",
              "CARE_SETTING" => 2,
              "CLINIC_NAME" => "",
              "DATE_OF_VACCINATION" => nil,
              "DOSE_SEQUENCE" => 1,
              "NHS_NUMBER" => patient.nhs_number.to_i,
              "ORGANISATION_CODE" => organisation.ods_code,
              "PERFORMING_PROFESSIONAL_EMAIL" => "",
              "PERSON_FORENAME" => patient.given_name,
              "PERSON_GENDER_CODE" => "Not known",
              "PERSON_POSTCODE" => patient.address_postcode,
              "PERSON_SURNAME" => patient.family_name,
              "SCHOOL_NAME" => "",
              "SCHOOL_URN" => 888_888,
              "TIME_OF_VACCINATION" => "",
              "VACCINATED" => "",
              "VACCINE_GIVEN" => "",
              "REASON_NOT_VACCINATED" => ""
            }
          )
          expect(rows.first["PERSON_DOB"].to_date).to eq(patient.date_of_birth)
        end
      end

      context "with a vaccinated patient" do
        let(:patient) do
          create(
            :patient,
            school:
              create(:location, :school, urn: "123456", name: "Waterloo Road")
          )
        end
        let(:patient_session) { create(:patient_session, patient:, session:) }
        let(:batch) { create(:batch, vaccine: programme.vaccines.active.first) }
        let(:administered_at) { Time.zone.local(2024, 1, 1, 12, 0o5, 20) }

        before do
          create(
            :vaccination_record,
            administered_at:,
            batch:,
            patient_session:,
            programme:,
            location_name: "A Clinic",
            performed_by: user
          )
        end

        it "adds a row to fill in" do
          expect(rows.count).to eq(1)
          expect(rows.first.except("PERSON_DOB", "DATE_OF_VACCINATION")).to eq(
            {
              "ANATOMICAL_SITE" => "left upper arm",
              "BATCH_EXPIRY_DATE" => batch.expiry,
              "BATCH_NUMBER" => batch.name,
              "CARE_SETTING" => 2,
              "CLINIC_NAME" => "A Clinic",
              "DOSE_SEQUENCE" => 1,
              "NHS_NUMBER" => patient.nhs_number.to_i,
              "ORGANISATION_CODE" => organisation.ods_code,
              "PERFORMING_PROFESSIONAL_EMAIL" => "nurse@example.com",
              "PERSON_FORENAME" => patient.given_name,
              "PERSON_GENDER_CODE" => "Not known",
              "PERSON_POSTCODE" => patient.address_postcode,
              "PERSON_SURNAME" => patient.family_name,
              "SCHOOL_NAME" => "Waterloo Road",
              "SCHOOL_URN" => 123_456,
              "TIME_OF_VACCINATION" => "12:05:20",
              "VACCINATED" => "Y",
              "VACCINE_GIVEN" => "Gardasil9",
              "REASON_NOT_VACCINATED" => ""
            }
          )
          expect(rows.first["PERSON_DOB"].to_date).to eq(patient.date_of_birth)
          expect(rows.first["DATE_OF_VACCINATION"].to_date).to eq(
            administered_at.to_date
          )
        end
      end
    end
  end
end
