# frozen_string_literal: true

describe Reports::OfflineSessionExporter do
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
  let(:user) { create(:user, email: "nurse@example.com", organisation:) }
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
            PERSON_FORENAME
            PERSON_SURNAME
            PERSON_DOB
            YEAR_GROUP
            PERSON_GENDER_CODE
            PERSON_POSTCODE
            NHS_NUMBER
            CONSENT_STATUS
            CONSENT_DETAILS
            HEALTH_QUESTION_ANSWERS
            TRIAGE_STATUS
            TRIAGED_BY
            TRIAGE_DATE
            TRIAGE_NOTES
            GILLICK_STATUS
            GILLICK_ASSESSMENT_DATE
            GILLICK_ASSESSED_BY
            GILLICK_ASSESSMENT_NOTES
            VACCINATED
            DATE_OF_VACCINATION
            TIME_OF_VACCINATION
            VACCINE_GIVEN
            PERFORMING_PROFESSIONAL_EMAIL
            BATCH_NUMBER
            BATCH_EXPIRY_DATE
            ANATOMICAL_SITE
            DOSE_SEQUENCE
            REASON_NOT_VACCINATED
            UUID
          ]
        )
      end
    end

    describe "rows" do
      subject(:rows) do
        workbook = RubyXL::Parser.parse_buffer(call)
        worksheet_to_hashes(workbook.worksheets[0])
      end

      let(:performed_at) { Time.zone.local(2024, 1, 1, 12, 5, 20) }
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
              "CONSENT_DETAILS" => "",
              "CONSENT_STATUS" => nil,
              "DATE_OF_VACCINATION" => nil,
              "DOSE_SEQUENCE" => 1,
              "GILLICK_ASSESSED_BY" => nil,
              "GILLICK_ASSESSMENT_DATE" => nil,
              "GILLICK_ASSESSMENT_NOTES" => nil,
              "GILLICK_STATUS" => "",
              "HEALTH_QUESTION_ANSWERS" => "",
              "NHS_NUMBER" => patient.nhs_number,
              "ORGANISATION_CODE" => organisation.ods_code,
              "PERFORMING_PROFESSIONAL_EMAIL" => "",
              "PERSON_FORENAME" => patient.given_name,
              "PERSON_GENDER_CODE" => "Not known",
              "PERSON_POSTCODE" => patient.address_postcode,
              "PERSON_SURNAME" => patient.family_name,
              "REASON_NOT_VACCINATED" => "",
              "SCHOOL_NAME" => location.name,
              "SCHOOL_URN" => location.urn,
              "TIME_OF_VACCINATION" => "",
              "TRIAGED_BY" => nil,
              "TRIAGE_DATE" => nil,
              "TRIAGE_NOTES" => nil,
              "TRIAGE_STATUS" => nil,
              "VACCINATED" => "",
              "VACCINE_GIVEN" => "",
              "UUID" => "",
              "YEAR_GROUP" => patient.year_group
            }
          )
          expect(rows.first["PERSON_DOB"].to_date).to eq(patient.date_of_birth)
        end
      end

      context "with a restricted patient" do
        before { create(:patient, :restricted, session:) }

        it "doesn't include the postcode" do
          expect(rows.count).to eq(1)
          expect(rows.first["PERSON_POSTCODE"]).to be_blank
        end
      end

      context "with a vaccinated patient" do
        let!(:vaccination_record) do
          create(
            :vaccination_record,
            performed_at:,
            batch:,
            patient_session:,
            programme:,
            performed_by: user
          )
        end

        it "adds a row with the vaccination details" do
          expect(rows.count).to eq(1)
          expect(
            rows.first.except(
              "BATCH_EXPIRY_DATE",
              "PERSON_DOB",
              "DATE_OF_VACCINATION"
            )
          ).to eq(
            {
              "ANATOMICAL_SITE" => "left upper arm",
              "BATCH_NUMBER" => batch.name,
              "CARE_SETTING" => 1,
              "CONSENT_DETAILS" => "",
              "CONSENT_STATUS" => nil,
              "DOSE_SEQUENCE" => 1,
              "GILLICK_ASSESSED_BY" => nil,
              "GILLICK_ASSESSMENT_DATE" => nil,
              "GILLICK_ASSESSMENT_NOTES" => nil,
              "GILLICK_STATUS" => "",
              "HEALTH_QUESTION_ANSWERS" => "",
              "NHS_NUMBER" => patient.nhs_number,
              "ORGANISATION_CODE" => organisation.ods_code,
              "PERFORMING_PROFESSIONAL_EMAIL" => "nurse@example.com",
              "PERSON_FORENAME" => patient.given_name,
              "PERSON_GENDER_CODE" => "Not known",
              "PERSON_POSTCODE" => patient.address_postcode,
              "PERSON_SURNAME" => patient.family_name,
              "REASON_NOT_VACCINATED" => "",
              "SCHOOL_NAME" => location.name,
              "SCHOOL_URN" => location.urn,
              "TIME_OF_VACCINATION" => "12:05:20",
              "TRIAGED_BY" => nil,
              "TRIAGE_DATE" => nil,
              "TRIAGE_NOTES" => nil,
              "TRIAGE_STATUS" => nil,
              "VACCINATED" => "Y",
              "VACCINE_GIVEN" => "Gardasil9",
              "UUID" => vaccination_record.uuid,
              "YEAR_GROUP" => patient.year_group
            }
          )
          expect(rows.first["BATCH_EXPIRY_DATE"].to_date).to eq(batch.expiry)
          expect(rows.first["PERSON_DOB"].to_date).to eq(patient.date_of_birth)
          expect(rows.first["DATE_OF_VACCINATION"].to_date).to eq(
            performed_at.to_date
          )
        end
      end

      context "with a patient who couldn't be vaccinated" do
        let!(:vaccination_record) do
          create(
            :vaccination_record,
            :not_administered,
            patient_session:,
            programme:,
            performed_at:,
            performed_by: user
          )
        end

        it "adds a row to fill in" do
          expect(rows.count).to eq(1)
          expect(rows.first.except("DATE_OF_VACCINATION", "PERSON_DOB")).to eq(
            {
              "ANATOMICAL_SITE" => "",
              "BATCH_EXPIRY_DATE" => nil,
              "BATCH_NUMBER" => nil,
              "CARE_SETTING" => 1,
              "CONSENT_DETAILS" => "",
              "CONSENT_STATUS" => nil,
              "DOSE_SEQUENCE" => "",
              "GILLICK_ASSESSED_BY" => nil,
              "GILLICK_ASSESSMENT_DATE" => nil,
              "GILLICK_ASSESSMENT_NOTES" => nil,
              "GILLICK_STATUS" => "",
              "HEALTH_QUESTION_ANSWERS" => "",
              "NHS_NUMBER" => patient.nhs_number,
              "ORGANISATION_CODE" => organisation.ods_code,
              "PERFORMING_PROFESSIONAL_EMAIL" => "nurse@example.com",
              "PERSON_FORENAME" => patient.given_name,
              "PERSON_GENDER_CODE" => "Not known",
              "PERSON_POSTCODE" => patient.address_postcode,
              "PERSON_SURNAME" => patient.family_name,
              "REASON_NOT_VACCINATED" => "unwell",
              "SCHOOL_NAME" => location.name,
              "SCHOOL_URN" => location.urn,
              "TIME_OF_VACCINATION" => "12:05:20",
              "TRIAGED_BY" => nil,
              "TRIAGE_DATE" => nil,
              "TRIAGE_NOTES" => nil,
              "TRIAGE_STATUS" => nil,
              "VACCINATED" => "N",
              "VACCINE_GIVEN" => nil,
              "UUID" => vaccination_record.uuid,
              "YEAR_GROUP" => patient.year_group
            }
          )
          expect(rows.first["DATE_OF_VACCINATION"].to_date).to eq(
            performed_at.to_date
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
            CLINIC_NAME
            PERSON_FORENAME
            PERSON_SURNAME
            PERSON_DOB
            YEAR_GROUP
            PERSON_GENDER_CODE
            PERSON_POSTCODE
            NHS_NUMBER
            CONSENT_STATUS
            CONSENT_DETAILS
            HEALTH_QUESTION_ANSWERS
            TRIAGE_STATUS
            TRIAGED_BY
            TRIAGE_DATE
            TRIAGE_NOTES
            GILLICK_STATUS
            GILLICK_ASSESSMENT_DATE
            GILLICK_ASSESSED_BY
            GILLICK_ASSESSMENT_NOTES
            VACCINATED
            DATE_OF_VACCINATION
            TIME_OF_VACCINATION
            VACCINE_GIVEN
            PERFORMING_PROFESSIONAL_EMAIL
            BATCH_NUMBER
            BATCH_EXPIRY_DATE
            ANATOMICAL_SITE
            DOSE_SEQUENCE
            REASON_NOT_VACCINATED
            UUID
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
              "CONSENT_DETAILS" => "",
              "CONSENT_STATUS" => nil,
              "CLINIC_NAME" => "",
              "DATE_OF_VACCINATION" => nil,
              "DOSE_SEQUENCE" => 1,
              "GILLICK_ASSESSED_BY" => nil,
              "GILLICK_ASSESSMENT_DATE" => nil,
              "GILLICK_ASSESSMENT_NOTES" => nil,
              "GILLICK_STATUS" => "",
              "HEALTH_QUESTION_ANSWERS" => "",
              "NHS_NUMBER" => patient.nhs_number,
              "ORGANISATION_CODE" => organisation.ods_code,
              "PERFORMING_PROFESSIONAL_EMAIL" => "",
              "PERSON_FORENAME" => patient.given_name,
              "PERSON_GENDER_CODE" => "Not known",
              "PERSON_POSTCODE" => patient.address_postcode,
              "PERSON_SURNAME" => patient.family_name,
              "REASON_NOT_VACCINATED" => "",
              "SCHOOL_NAME" => "",
              "SCHOOL_URN" => "888888",
              "TIME_OF_VACCINATION" => "",
              "TRIAGED_BY" => nil,
              "TRIAGE_DATE" => nil,
              "TRIAGE_NOTES" => nil,
              "TRIAGE_STATUS" => nil,
              "VACCINATED" => "",
              "VACCINE_GIVEN" => "",
              "UUID" => "",
              "YEAR_GROUP" => patient.year_group
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
        let(:performed_at) { Time.zone.local(2024, 1, 1, 12, 5, 20) }

        let!(:vaccination_record) do
          create(
            :vaccination_record,
            performed_at:,
            batch:,
            patient_session:,
            programme:,
            location_name: "A Clinic",
            performed_by: user
          )
        end

        it "adds a row to fill in" do
          expect(rows.count).to eq(1)
          expect(
            rows.first.except(
              "BATCH_EXPIRY_DATE",
              "PERSON_DOB",
              "DATE_OF_VACCINATION"
            )
          ).to eq(
            {
              "ANATOMICAL_SITE" => "left upper arm",
              "BATCH_NUMBER" => batch.name,
              "CARE_SETTING" => 2,
              "CONSENT_DETAILS" => "",
              "CONSENT_STATUS" => nil,
              "CLINIC_NAME" => "A Clinic",
              "DOSE_SEQUENCE" => 1,
              "GILLICK_ASSESSED_BY" => nil,
              "GILLICK_ASSESSMENT_DATE" => nil,
              "GILLICK_ASSESSMENT_NOTES" => nil,
              "GILLICK_STATUS" => "",
              "HEALTH_QUESTION_ANSWERS" => "",
              "NHS_NUMBER" => patient.nhs_number,
              "ORGANISATION_CODE" => organisation.ods_code,
              "PERFORMING_PROFESSIONAL_EMAIL" => "nurse@example.com",
              "PERSON_FORENAME" => patient.given_name,
              "PERSON_GENDER_CODE" => "Not known",
              "PERSON_POSTCODE" => patient.address_postcode,
              "PERSON_SURNAME" => patient.family_name,
              "REASON_NOT_VACCINATED" => "",
              "SCHOOL_NAME" => "Waterloo Road",
              "SCHOOL_URN" => "123456",
              "TIME_OF_VACCINATION" => "12:05:20",
              "TRIAGED_BY" => nil,
              "TRIAGE_DATE" => nil,
              "TRIAGE_NOTES" => nil,
              "TRIAGE_STATUS" => nil,
              "VACCINATED" => "Y",
              "VACCINE_GIVEN" => "Gardasil9",
              "UUID" => vaccination_record.uuid,
              "YEAR_GROUP" => patient.year_group
            }
          )
          expect(rows.first["BATCH_EXPIRY_DATE"].to_date).to eq(batch.expiry)
          expect(rows.first["PERSON_DOB"].to_date).to eq(patient.date_of_birth)
          expect(rows.first["DATE_OF_VACCINATION"].to_date).to eq(
            performed_at.to_date
          )
        end
      end
    end
  end
end
