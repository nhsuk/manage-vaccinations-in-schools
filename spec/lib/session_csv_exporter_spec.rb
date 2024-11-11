# frozen_string_literal: true

describe SessionCSVExporter do
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
      subject(:headers) { CSV.parse(call).first }

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
      subject(:rows) { CSV.parse(call, headers: true) }

      it { should be_empty }

      context "with a patient" do
        let!(:patient) { create(:patient, session:) }

        it "adds a row to fill in" do
          expect(rows.count).to eq(1)
          expect(rows.first.to_hash).to eq(
            {
              "ANATOMICAL_SITE" => "",
              "BATCH_EXPIRY_DATE" => "",
              "BATCH_NUMBER" => "",
              "CARE_SETTING" => "1",
              "DATE_OF_VACCINATION" => "",
              "DOSE_SEQUENCE" => "1",
              "NHS_NUMBER" => patient.nhs_number,
              "ORGANISATION_CODE" => organisation.ods_code,
              "PERFORMING_PROFESSIONAL_EMAIL" => "",
              "PERSON_DOB" => patient.date_of_birth.strftime("%Y%m%d"),
              "PERSON_FORENAME" => patient.given_name,
              "PERSON_GENDER_CODE" => "Not known",
              "PERSON_POSTCODE" => patient.address_postcode,
              "PERSON_SURNAME" => patient.family_name,
              "SCHOOL_NAME" => location.name,
              "SCHOOL_URN" => location.urn,
              "TIME_OF_VACCINATION" => "",
              "VACCINATED" => "",
              "VACCINE_GIVEN" => ""
            }
          )
        end
      end

      context "with a vaccinated patient" do
        let(:patient) { create(:patient) }
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
            performed_by: user
          )
        end

        it "adds a row to fill in" do
          expect(rows.count).to eq(1)
          expect(rows.first.to_hash).to eq(
            {
              "ANATOMICAL_SITE" => "left upper arm",
              "BATCH_EXPIRY_DATE" => batch.expiry.strftime("%Y%m%d"),
              "BATCH_NUMBER" => batch.name,
              "CARE_SETTING" => "1",
              "DATE_OF_VACCINATION" => "20240101",
              "DOSE_SEQUENCE" => "1",
              "NHS_NUMBER" => patient.nhs_number,
              "ORGANISATION_CODE" => organisation.ods_code,
              "PERFORMING_PROFESSIONAL_EMAIL" => "nurse@example.com",
              "PERSON_DOB" => patient.date_of_birth.strftime("%Y%m%d"),
              "PERSON_FORENAME" => patient.given_name,
              "PERSON_GENDER_CODE" => "Not known",
              "PERSON_POSTCODE" => patient.address_postcode,
              "PERSON_SURNAME" => patient.family_name,
              "SCHOOL_NAME" => location.name,
              "SCHOOL_URN" => location.urn,
              "TIME_OF_VACCINATION" => "12:05:20",
              "VACCINATED" => "Y",
              "VACCINE_GIVEN" => "Gardasil9"
            }
          )
        end
      end
    end
  end

  context "a clinic session" do
    let(:location) { create(:location, :generic_clinic, team:) }

    it { should_not be_blank }

    describe "headers" do
      subject(:headers) { CSV.parse(call).first }

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
      subject(:rows) { CSV.parse(call, headers: true) }

      it { should be_empty }

      context "with a patient" do
        let!(:patient) { create(:patient, session:) }

        it "adds a row to fill in" do
          expect(rows.count).to eq(1)
          expect(rows.first.to_hash).to eq(
            {
              "ANATOMICAL_SITE" => "",
              "BATCH_EXPIRY_DATE" => "",
              "BATCH_NUMBER" => "",
              "CARE_SETTING" => "2",
              "CLINIC_NAME" => "",
              "DATE_OF_VACCINATION" => "",
              "DOSE_SEQUENCE" => "1",
              "NHS_NUMBER" => patient.nhs_number,
              "ORGANISATION_CODE" => organisation.ods_code,
              "PERFORMING_PROFESSIONAL_EMAIL" => "",
              "PERSON_DOB" => patient.date_of_birth.strftime("%Y%m%d"),
              "PERSON_FORENAME" => patient.given_name,
              "PERSON_GENDER_CODE" => "Not known",
              "PERSON_POSTCODE" => patient.address_postcode,
              "PERSON_SURNAME" => patient.family_name,
              "SCHOOL_NAME" => "",
              "SCHOOL_URN" => "888888",
              "TIME_OF_VACCINATION" => "",
              "VACCINATED" => "",
              "VACCINE_GIVEN" => ""
            }
          )
        end
      end

      context "with a vaccinated patient" do
        let(:patient) { create(:patient) }
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
          expect(rows.first.to_hash).to eq(
            {
              "ANATOMICAL_SITE" => "left upper arm",
              "BATCH_EXPIRY_DATE" => batch.expiry.strftime("%Y%m%d"),
              "BATCH_NUMBER" => batch.name,
              "CARE_SETTING" => "2",
              "CLINIC_NAME" => "A Clinic",
              "DATE_OF_VACCINATION" => "20240101",
              "DOSE_SEQUENCE" => "1",
              "NHS_NUMBER" => patient.nhs_number,
              "ORGANISATION_CODE" => organisation.ods_code,
              "PERFORMING_PROFESSIONAL_EMAIL" => "nurse@example.com",
              "PERSON_DOB" => patient.date_of_birth.strftime("%Y%m%d"),
              "PERSON_FORENAME" => patient.given_name,
              "PERSON_GENDER_CODE" => "Not known",
              "PERSON_POSTCODE" => patient.address_postcode,
              "PERSON_SURNAME" => patient.family_name,
              "SCHOOL_NAME" => "",
              "SCHOOL_URN" => "888888",
              "TIME_OF_VACCINATION" => "12:05:20",
              "VACCINATED" => "Y",
              "VACCINE_GIVEN" => "Gardasil9"
            }
          )
        end
      end
    end
  end
end
