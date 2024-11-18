# frozen_string_literal: true

describe Reports::ProgrammeVaccinationsExporter do
  subject(:call) do
    described_class.call(
      organisation:,
      programme:,
      start_date: nil,
      end_date: nil
    )
  end

  let(:programme) { create(:programme, :hpv) }
  let(:organisation) { create(:organisation, programmes: [programme]) }
  let(:user) do
    create(
      :user,
      email: "nurse@example.com",
      given_name: "Nurse",
      family_name: "Test",
      organisation:
    )
  end
  let(:team) { create(:team, organisation:) }
  let(:session) { create(:session, location:, organisation:, programme:) }

  describe "headers" do
    subject(:headers) { CSV.parse(call).first }

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
          PERFORMING_PROFESSIONAL_FORENAME
          PERFORMING_PROFESSIONAL_SURNAME
          BATCH_NUMBER
          BATCH_EXPIRY_DATE
          ANATOMICAL_SITE
          ROUTE_OF_VACCINATION
          DOSE_SEQUENCE
          REASON_NOT_VACCINATED
        ]
      )
    end
  end

  describe "rows" do
    subject(:rows) { CSV.parse(call, headers: true) }

    context "a school session" do
      let(:location) { create(:location, :school, team:) }

      it { should be_empty }

      context "with a vaccinated patient" do
        let(:patient) { create(:patient, year_group: 8) }
        let(:patient_session) { create(:patient_session, patient:, session:) }
        let(:batch) { create(:batch, vaccine: programme.vaccines.active.first) }
        let(:performed_at) { Time.zone.local(2024, 1, 1, 12, 5, 20) }

        before do
          create(
            :vaccination_record,
            batch:,
            patient_session:,
            performed_at:,
            programme:,
            performed_by: user
          )
        end

        it "has a row" do
          expect(rows.count).to eq(1)
          expect(rows.first.to_hash).to eq(
            {
              "ANATOMICAL_SITE" => "left upper arm",
              "BATCH_EXPIRY_DATE" => batch.expiry.strftime("%Y%m%d"),
              "BATCH_NUMBER" => batch.name,
              "CARE_SETTING" => "1",
              "CLINIC_NAME" => "",
              "CONSENT_DETAILS" => "",
              "CONSENT_STATUS" => "",
              "DATE_OF_VACCINATION" => "20240101",
              "DOSE_SEQUENCE" => "1",
              "GILLICK_ASSESSED_BY" => "",
              "GILLICK_ASSESSMENT_DATE" => "",
              "GILLICK_ASSESSMENT_NOTES" => "",
              "GILLICK_STATUS" => "",
              "HEALTH_QUESTION_ANSWERS" => "",
              "NHS_NUMBER" => patient.nhs_number,
              "ORGANISATION_CODE" => organisation.ods_code,
              "PERFORMING_PROFESSIONAL_EMAIL" => "nurse@example.com",
              "PERFORMING_PROFESSIONAL_FORENAME" => "Nurse",
              "PERFORMING_PROFESSIONAL_SURNAME" => "Test",
              "PERSON_DOB" => patient.date_of_birth.strftime("%Y%m%d"),
              "PERSON_FORENAME" => patient.given_name,
              "PERSON_GENDER_CODE" => "Not known",
              "PERSON_POSTCODE" => patient.address_postcode,
              "PERSON_SURNAME" => patient.family_name,
              "REASON_NOT_VACCINATED" => "",
              "ROUTE_OF_VACCINATION" => "intramuscular",
              "SCHOOL_NAME" => location.name,
              "SCHOOL_URN" => location.urn,
              "TIME_OF_VACCINATION" => "12:05:20",
              "TRIAGED_BY" => "",
              "TRIAGE_DATE" => "",
              "TRIAGE_NOTES" => "",
              "TRIAGE_STATUS" => "",
              "VACCINATED" => "Y",
              "VACCINE_GIVEN" => "Gardasil9",
              "YEAR_GROUP" => "8"
            }
          )
        end
      end
    end

    context "a clinic session" do
      let(:location) { create(:location, :generic_clinic, team:) }

      it { should be_empty }

      context "with a vaccinated patient" do
        let(:patient) { create(:patient, year_group: 8) }
        let(:patient_session) { create(:patient_session, patient:, session:) }
        let(:batch) { create(:batch, vaccine: programme.vaccines.active.first) }
        let(:performed_at) { Time.zone.local(2024, 1, 1, 12, 5, 20) }

        before do
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

        it "has a row" do
          expect(rows.count).to eq(1)
          expect(rows.first.to_hash).to eq(
            {
              "ANATOMICAL_SITE" => "left upper arm",
              "BATCH_EXPIRY_DATE" => batch.expiry.strftime("%Y%m%d"),
              "BATCH_NUMBER" => batch.name,
              "CARE_SETTING" => "2",
              "CLINIC_NAME" => "A Clinic",
              "CONSENT_DETAILS" => "",
              "CONSENT_STATUS" => "",
              "DATE_OF_VACCINATION" => "20240101",
              "DOSE_SEQUENCE" => "1",
              "GILLICK_ASSESSED_BY" => "",
              "GILLICK_ASSESSMENT_DATE" => "",
              "GILLICK_ASSESSMENT_NOTES" => "",
              "GILLICK_STATUS" => "",
              "HEALTH_QUESTION_ANSWERS" => "",
              "NHS_NUMBER" => patient.nhs_number,
              "ORGANISATION_CODE" => organisation.ods_code,
              "PERFORMING_PROFESSIONAL_EMAIL" => "nurse@example.com",
              "PERFORMING_PROFESSIONAL_FORENAME" => "Nurse",
              "PERFORMING_PROFESSIONAL_SURNAME" => "Test",
              "PERSON_DOB" => patient.date_of_birth.strftime("%Y%m%d"),
              "PERSON_FORENAME" => patient.given_name,
              "PERSON_GENDER_CODE" => "Not known",
              "PERSON_POSTCODE" => patient.address_postcode,
              "PERSON_SURNAME" => patient.family_name,
              "REASON_NOT_VACCINATED" => "",
              "ROUTE_OF_VACCINATION" => "intramuscular",
              "SCHOOL_NAME" => "",
              "SCHOOL_URN" => "888888",
              "TIME_OF_VACCINATION" => "12:05:20",
              "TRIAGED_BY" => "",
              "TRIAGE_DATE" => "",
              "TRIAGE_NOTES" => "",
              "TRIAGE_STATUS" => "",
              "VACCINATED" => "Y",
              "VACCINE_GIVEN" => "Gardasil9",
              "YEAR_GROUP" => "8"
            }
          )
        end
      end
    end

    context "with consent" do
      let(:session) { create(:session, programme:, organisation:) }
      let(:patient) { create(:patient, :vaccinated, session:, programme:) }

      before do
        parent = create(:parent, full_name: "John Smith")
        create(:parent_relationship, :father, parent:, patient:)
        recorded_at = Time.zone.local(2024, 1, 1, 12, 5, 20)
        create(:consent, :given, patient:, parent:, programme:, recorded_at:)
      end

      it "includes the information" do
        expect(rows.first.to_hash).to include(
          "CONSENT_DETAILS" =>
            "Given by John Smith at 2024-01-01 12:05:20 +0000",
          "CONSENT_STATUS" => "Given",
          "HEALTH_QUESTION_ANSWERS" =>
            "Is there anything else we should know? No from Dad"
        )
      end
    end

    context "with a gillick assessment" do
      let(:session) { create(:session, programme:, organisation:) }
      let(:patient_session) do
        create(:patient_session, :vaccinated, programme:, session:)
      end

      before do
        performed_by = create(:user, given_name: "Test", family_name: "Nurse")
        updated_at = Date.new(2024, 1, 1)
        create(
          :gillick_assessment,
          :competent,
          patient_session:,
          performed_by:,
          updated_at:
        )
      end

      it "includes the information" do
        expect(rows.first.to_hash).to include(
          "GILLICK_ASSESSED_BY" => "Test Nurse",
          "GILLICK_ASSESSMENT_DATE" => "20240101",
          "GILLICK_ASSESSMENT_NOTES" => "Assessed as Gillick competent",
          "GILLICK_STATUS" => "Gillick competent"
        )
      end
    end

    context "with a triage assessment" do
      let(:session) { create(:session, programme:, organisation:) }
      let(:performed_by) do
        create(:user, given_name: "Test", family_name: "Nurse")
      end

      before do
        create(
          :patient_session,
          :vaccinated,
          programme:,
          session:,
          user: performed_by
        )
      end

      it "includes the information" do
        expect(rows.first.to_hash).to include(
          "TRIAGED_BY" => "Test Nurse",
          "TRIAGE_DATE" => Date.current.strftime("%Y%m%d"),
          "TRIAGE_NOTES" => "Okay to vaccinate",
          "TRIAGE_STATUS" => "Ready to vaccinate"
        )
      end
    end
  end
end
