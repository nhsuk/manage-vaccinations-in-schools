# frozen_string_literal: true

describe ImmunisationImport::Row do
  subject(:immunisation_import_row) do
    described_class.new(data:, organisation:)
  end

  let(:programmes) { [create(:programme, :flu)] }
  let(:organisation) { create(:organisation, ods_code: "abc", programmes:) }

  let(:nhs_number) { "1234567890" }
  let(:given_name) { "Harry" }
  let(:family_name) { "Potter" }
  let(:date_of_birth) { "20120101" }
  let(:address_postcode) { "SW1A 1AA" }
  let(:vaccinator) { create(:user, organisation:) }
  let(:valid_common_data) do
    {
      "ORGANISATION_CODE" => "abc",
      "VACCINATED" => "Y",
      "BATCH_EXPIRY_DATE" => "20210101",
      "BATCH_NUMBER" => "123",
      "SCHOOL_NAME" => "Hogwarts",
      "SCHOOL_URN" => "123456",
      "PERSON_FORENAME" => given_name,
      "PERSON_SURNAME" => family_name,
      "PERSON_DOB" => date_of_birth,
      "PERSON_POSTCODE" => address_postcode,
      "PERSON_GENDER_CODE" => "Male",
      "NHS_NUMBER" => nhs_number,
      "DATE_OF_VACCINATION" => "20240101"
    }
  end
  let(:valid_flu_data) do
    valid_common_data.deep_dup.merge(
      "PROGRAMME" => "Flu",
      "VACCINE_GIVEN" => "AstraZeneca Fluenz Tetra LAIV",
      "ANATOMICAL_SITE" => "nasal",
      "PERFORMING_PROFESSIONAL_FORENAME" => "John",
      "PERFORMING_PROFESSIONAL_SURNAME" => "Smith"
    )
  end
  let(:valid_hpv_data) do
    valid_common_data.deep_dup.merge(
      "PROGRAMME" => "HPV",
      "VACCINE_GIVEN" => "Gardasil9",
      "ANATOMICAL_SITE" => "Left Upper Arm",
      "DOSE_SEQUENCE" => "1",
      "CARE_SETTING" => "1"
    )
  end
  let(:valid_data) { valid_flu_data }

  let!(:location) { create(:school, urn: "123456", name: "Waterloo Road") }

  describe "validations" do
    context "with an empty row" do
      let(:data) { {} }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:administered]).to include(
          /You need to record whether the child was vaccinated or not/
        )
        expect(immunisation_import_row.errors[:programme_name]).to include(
          "This programme is not available in this session"
        )
      end
    end

    context "when missing fields" do
      let(:data) { { "VACCINATED" => "Y" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:patient_date_of_birth]).to eq(
          ["Enter a date of birth in the correct format."]
        )
        expect(immunisation_import_row.errors[:patient_gender_code]).to eq(
          ["Enter a gender or gender code."]
        )
        expect(immunisation_import_row.errors[:patient_postcode]).to eq(
          ["Enter a valid postcode, such as SW1A 1AA"]
        )
      end

      context "with an NHS number and missing fields" do
        let(:data) { { "VACCINATED" => "Y", "NHS_NUMBER" => nhs_number } }

        it "doesn't require a postcode" do
          expect(immunisation_import_row).to be_invalid
          expect(immunisation_import_row.errors[:patient_postcode]).to be_empty
        end
      end
    end

    context "with an invalid vaccine" do
      let(:data) { { "VACCINATED" => "Y", "VACCINE_GIVEN" => "test" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:vaccine_name]).to eq(
          ["This vaccine is not available in this session"]
        )
      end
    end

    context "with an invalid postcode" do
      let(:data) { { "PERSON_POSTCODE" => "ABC DEF" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:patient_postcode]).to include(
          "Enter a valid postcode, such as SW1A 1AA"
        )
      end
    end

    context "with an invalid gender code" do
      let(:data) { { "PERSON_GENDER_CODE" => "10" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:patient_gender_code]).to eq(
          ["Enter a gender or gender code."]
        )
      end
    end

    context "with an invalid date of vaccination" do
      let(:data) { { "DATE_OF_VACCINATION" => "21000101" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
      end
    end

    context "with a date and time of vaccination in the future" do
      around { |example| freeze_time { example.run } }

      let(:data) do
        {
          "DATE_OF_VACCINATION" => Date.current.strftime("%Y%m%d"),
          "TIME_OF_VACCINATION" => 1.second.from_now.strftime("%H:%M:%S")
        }
      end

      it "has an error" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:time_of_vaccination]).to include(
          "Enter a time in the past"
        )
      end
    end

    context "with a date of vaccination before the child was born" do
      around { |example| freeze_time { example.run } }

      let(:data) do
        { "PERSON_DOB" => "20100101", "DATE_OF_VACCINATION" => "20090101" }
      end

      it "has an error" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:date_of_vaccination]).to include(
          "The vaccination date is before the date of birth"
        )
      end
    end

    context "when vaccinated and a reason not given" do
      let(:data) do
        { "VACCINATED" => "Y", "REASON_NOT_VACCINATED" => "unwell" }
      end

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:reason_not_vaccinated]).to eq(
          ["must be blank"]
        )
      end
    end

    context "for a vaccination administered today, with no time provided" do
      around { |example| freeze_time { example.run } }

      before { immunisation_import_row.valid? }

      let(:data) do
        {
          "DATE_OF_VACCINATION" => Date.current.strftime("%Y%m%d"),
          "TIME_OF_VACCINATION" => nil
        }
      end

      it "has a valid time of vaccination" do
        expect(immunisation_import_row.errors[:time_of_vaccination]).to be_empty
      end
    end

    context "when date doesn't match an existing session" do
      subject(:errors) { immunisation_import_row.errors[:date_of_vaccination] }

      before { immunisation_import_row.valid? }

      context "when importing for an existing session" do
        let(:data) do
          {
            "DATE_OF_VACCINATION" => "#{Date.current.academic_year}0901",
            "SESSION_ID" => session.id.to_s
          }
        end

        let(:session) { create(:session, organisation:, programmes:) }

        it do
          expect(errors).to include(
            "Enter a date that matches when the vaccination session took place"
          )
        end
      end

      context "when importing without a session" do
        let(:data) { { "DATE_OF_VACCINATION" => "20220101" } }

        it { should be_empty }
      end
    end

    context "with an invalid time of vaccination" do
      let(:data) { { "TIME_OF_VACCINATION" => "abc" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:time_of_vaccination]).to eq(
          ["Enter a time in the correct format"]
        )
      end
    end

    context "with an invalid NHS number" do
      let(:data) { { "NHS_NUMBER" => "abc" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:patient_nhs_number]).to eq(
          ["Enter an NHS number with 10 characters."]
        )
      end
    end

    context "with an invalid patient date of birth" do
      let(:data) { { "PERSON_DOB" => "21000101" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:patient_date_of_birth]).to eq(
          ["Enter a date of birth in the past."]
        )
      end
    end

    context "with more than two matching patients" do
      let(:data) do
        {
          "PERSON_FORENAME" => "John",
          "PERSON_SURNAME" => "Smith",
          "PERSON_DOB" => "19900901",
          "PERSON_POSTCODE" => "ABC DEF"
        }
      end

      before do
        create_list(
          :patient,
          2,
          given_name: "John",
          family_name: "Smith",
          date_of_birth: Date.new(1990, 9, 1)
        )
      end

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:existing_patients]).to eq(
          [
            "Two or more possible patients match the patient first name, last name, date of birth or postcode."
          ]
        )
      end
    end

    context "with an invalid dose sequence" do
      let(:programmes) { [create(:programme, :hpv)] }

      let(:data) { { "PROGRAMME" => "HPV", "DOSE_SEQUENCE" => "4" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:dose_sequence]).to include(
          /must be less than/
        )
      end
    end

    context "with an invalid session ID" do
      let(:data) { { "SESSION_ID" => "abc" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:session_id]).to include(
          "The session ID is not recognised. Download the offline spreadsheet and copy the session ID " \
            "for this row from there, or contact our support organisation."
        )
      end
    end

    context "with a session ID that doesn't exist" do
      let(:data) { { "SESSION_ID" => "123" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:session_id]).to include(
          "The session ID is not recognised. Download the offline spreadsheet and copy the session ID " \
            "for this row from there, or contact our support organisation."
        )
      end
    end

    context "vaccination in a session and no organisation provided" do
      let(:data) { { "SESSION_ID" => session.id.to_s } }

      let(:session) { create(:session, organisation:, programmes:) }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:performed_ods_code]).to eq(
          ["Enter an organisation code."]
        )
      end
    end

    context "vaccination in a session and invalid programme" do
      let(:data) do
        { "SESSION_ID" => session.id.to_s, "PROGRAMME" => "MenACWY" }
      end

      let(:programmes) do
        [create(:programme, :hpv), create(:programme, :menacwy)]
      end
      let(:session) do
        create(:session, organisation:, programmes: [programmes.first])
      end

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:programme_name]).to eq(
          ["This programme is not available in this session"]
        )
      end
    end

    context "vaccination in a session, no vaccinator details provided" do
      let(:data) do
        valid_data.except(
          "PERFORMING_PROFESSIONAL_EMAIL",
          "PERFORMING_PROFESSIONAL_FORENAME",
          "PERFORMING_PROFESSIONAL_SURNAME"
        ).merge(
          "DATE_OF_VACCINATION" => "#{Date.current.academic_year}0901",
          "VACCINATED" => "Y",
          "SESSION_ID" => session.id.to_s
        )
      end

      let(:session) { create(:session, organisation:, programmes:) }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:performed_by_user]).to include(
          "Enter a valid email address"
        )
        expect(
          immunisation_import_row.errors[:performed_by_given_name]
        ).to be_empty
        expect(
          immunisation_import_row.errors[:performed_by_family_name]
        ).to be_empty
      end
    end

    context "vaccination in a session, vaccinator email not provided but forename and surname are" do
      let(:data) do
        valid_data.except("PERFORMING_PROFESSIONAL_EMAIL").merge(
          "PERFORMING_PROFESSIONAL_FORENAME" => "John",
          "PERFORMING_PROFESSIONAL_SURNAME" => "Smith",
          "DATE_OF_VACCINATION" => "#{Date.current.academic_year}0901",
          "VACCINATED" => "Y",
          "SESSION_ID" => session.id.to_s
        )
      end

      let(:session) { create(:session, organisation:, programmes:) }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:performed_by_user]).to include(
          "Enter a valid email address"
        )
      end
    end

    context "vaccination in a MenACWY session and a dose sequence is provided" do
      let(:data) do
        {
          "SESSION_ID" => session.id.to_s,
          "PROGRAMME" => "MenACWY",
          "DOSE_SEQUENCE" => "1"
        }
      end

      let(:programmes) { [create(:programme, :menacwy)] }
      let(:session) { create(:session, organisation:, programmes:) }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:dose_sequence]).to eq(
          ["Do not provide a dose sequence for this programme (leave blank)"]
        )
      end
    end

    context "vaccination in a Td/IPV session and a dose sequence is provided" do
      let(:data) do
        {
          "SESSION_ID" => session.id.to_s,
          "PROGRAMME" => "3-in-1",
          "DOSE_SEQUENCE" => "1"
        }
      end

      let(:programmes) { [create(:programme, :td_ipv)] }
      let(:session) { create(:session, organisation:, programmes:) }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:dose_sequence]).to eq(
          ["Do not provide a dose sequence for this programme (leave blank)"]
        )
      end
    end

    context "HPV vaccination in previous academic year, no vaccinator details provided" do
      let(:programmes) { [create(:programme, :hpv)] }

      let(:data) do
        valid_hpv_data.except(
          "PERFORMING_PROFESSIONAL_EMAIL",
          "PERFORMING_PROFESSIONAL_FORENAME",
          "PERFORMING_PROFESSIONAL_SURNAME"
        ).merge("DATE_OF_VACCINATION" => "20220101")
      end

      it { should be_valid }
    end

    context "HPV vaccination in previous academic year, vaccinator email provided but doesn't exist" do
      let(:data) do
        valid_hpv_data.merge(
          "PERFORMING_PROFESSIONAL_EMAIL" => "non-existent@example.com",
          "DATE_OF_VACCINATION" => "20220101"
        )
      end

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:performed_by_user]).to include(
          "Enter a valid email address"
        )
      end
    end

    context "Flu vaccination in previous academic year, no vaccinator details provided" do
      let(:data) do
        valid_flu_data.except(
          "PERFORMING_PROFESSIONAL_EMAIL",
          "PERFORMING_PROFESSIONAL_FORENAME",
          "PERFORMING_PROFESSIONAL_SURNAME"
        ).merge("DATE_OF_VACCINATION" => "20220101")
      end

      it { should be_invalid }
    end

    context "vaccination in a session, with a delivery site that is not appropriate for HPV" do
      let(:programmes) { [create(:programme, :hpv)] }
      let(:session) { create(:session, organisation:, programmes:) }

      let(:data) do
        valid_hpv_data.merge(
          "ANATOMICAL_SITE" => "nasal",
          "VACCINATED" => "Y",
          "VACCINE_GIVEN" => "Gardasil9",
          "DATE_OF_VACCINATION" => "#{Date.current.academic_year}0901",
          "SESSION_ID" => session.id.to_s
        )
      end

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:delivery_site]).to eq(
          ["Enter a anatomical site that is appropriate for the vaccine."]
        )
      end
    end

    context "vaccination in a previous academic year, with a delivery site that's typically not appropriate for HPV" do
      let(:programmes) { [create(:programme, :hpv)] }

      let(:data) do
        {
          "ANATOMICAL_SITE" => "left buttock",
          "VACCINATED" => "Y",
          "VACCINE_GIVEN" => "Gardasil9",
          "DATE_OF_VACCINATION" => "20220101"
        }
      end

      it "raises no errors on delivery site to be more permissive of legacy records" do
        immunisation_import_row.valid?
        expect(immunisation_import_row.errors[:delivery_site]).to be_empty
      end
    end

    context "vaccination in a session, with a delivery site that is not appropriate for flu" do
      let(:programmes) { [create(:programme, :flu)] }
      let(:session) { create(:session, organisation:, programmes:) }

      let(:data) do
        {
          "ANATOMICAL_SITE" => "left buttock",
          "VACCINATED" => "Y",
          "PROGRAMME" => "Flu",
          "VACCINE_GIVEN" => "AstraZeneca Fluenz Tetra LAIV",
          "DATE_OF_VACCINATION" => "#{Date.current.academic_year}0901",
          "SESSION_ID" => session.id.to_s
        }
      end

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:delivery_site]).to eq(
          ["Enter a anatomical site that is appropriate for the vaccine."]
        )
      end
    end

    context "vaccination in a session without a batch" do
      let(:programmes) { [create(:programme, :flu)] }

      let(:data) do
        {
          "VACCINATED" => "Y",
          "PROGRAMME" => "Flu",
          "DATE_OF_VACCINATION" => "#{Date.current.academic_year}0901",
          "SESSION_ID" => session.id.to_s
        }
      end

      let(:session) { create(:session, organisation:, programmes:) }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:batch_expiry]).to eq(
          ["Enter a batch expiry date."]
        )
        expect(immunisation_import_row.errors[:batch_name]).to eq(
          ["Enter a batch number."]
        )
      end
    end

    context "vaccination in a session without a delivery site" do
      let(:programmes) { [create(:programme, :flu)] }

      let(:data) do
        {
          "VACCINATED" => "Y",
          "PROGRAMME" => "Flu",
          "DATE_OF_VACCINATION" => "#{Date.current.academic_year}0901",
          "SESSION_ID" => session.id.to_s
        }
      end

      let(:session) { create(:session, organisation:, programmes:) }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:delivery_site]).to eq(
          ["Enter an anatomical site."]
        )
      end
    end

    context "with valid fields for Flu" do
      let(:programmes) { [create(:programme, :flu)] }

      let(:data) do
        {
          "ORGANISATION_CODE" => "abc",
          "VACCINATED" => "Y",
          "BATCH_EXPIRY_DATE" => "20210101",
          "BATCH_NUMBER" => "123",
          "ANATOMICAL_SITE" => "nasal",
          "SCHOOL_NAME" => "Hogwarts",
          "SCHOOL_URN" => "123456",
          "PERSON_FORENAME" => "Harry",
          "PERSON_SURNAME" => "Potter",
          "PERSON_DOB" => "20120101",
          "PERSON_POSTCODE" => "SW1A 1AA",
          "PERSON_GENDER_CODE" => "Male",
          "DATE_OF_VACCINATION" => "20240101",
          "PROGRAMME" => "Flu",
          "VACCINE_GIVEN" => "AstraZeneca Fluenz Tetra LAIV",
          "PERFORMING_PROFESSIONAL_FORENAME" => "John",
          "PERFORMING_PROFESSIONAL_SURNAME" => "Smith"
        }
      end

      it { should be_valid }

      context "with a performing profession email provided as well" do
        before { data["PERFORMING_PROFESSIONAL_EMAIL"] = create(:user).email }

        it { should be_valid }

        it "ignores the performing professional fields" do
          expect(immunisation_import_row.performed_by_given_name).to be_nil
          expect(immunisation_import_row.performed_by_family_name).to be_nil
        end
      end
    end

    context "with valid fields for HPV" do
      let(:programmes) { [create(:programme, :hpv)] }

      let(:data) do
        {
          "ORGANISATION_CODE" => "abc",
          "BATCH_EXPIRY_DATE" => "20210101",
          "BATCH_NUMBER" => "123",
          "ANATOMICAL_SITE" => "left thigh",
          "SCHOOL_NAME" => "Hogwarts",
          "SCHOOL_URN" => "123456",
          "PERSON_FORENAME" => "Harry",
          "PERSON_SURNAME" => "Potter",
          "PERSON_DOB" => "20120101",
          "PERSON_POSTCODE" => "SW1A 1AA",
          "PERSON_GENDER_CODE" => "Male",
          "DATE_OF_VACCINATION" => "20240101",
          "PROGRAMME" => "HPV",
          "VACCINE_GIVEN" => "Gardasil9",
          "DOSE_SEQUENCE" => "1",
          "CARE_SETTING" => "1"
        }
      end

      it { should be_valid }
    end
  end

  describe "#patient" do
    subject(:patient) { immunisation_import_row.patient }

    context "without patient data" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with new patient data" do
      let(:data) { valid_data }

      it { should_not be_nil }
    end

    context "with an existing patient matching NHS number" do
      let(:data) { valid_data }

      let(:other_patient) { create(:patient, nhs_number:) }

      it { should eq(other_patient) }
    end

    context "without an NHS number and an existing patient matching first name, last name and date of birth" do
      let(:data) { valid_data.except("NHS_NUMBER") }

      let(:other_patient) do
        create(
          :patient,
          given_name:,
          family_name:,
          nhs_number:,
          date_of_birth: Date.parse(date_of_birth)
        )
      end

      it { should eq(other_patient) }
    end

    context "without an NHS number and an existing patient matching first name, last name and postcode" do
      let(:data) { valid_data.except("NHS_NUMBER") }

      let(:other_patient) do
        create(
          :patient,
          given_name:,
          family_name:,
          address_postcode:,
          nhs_number:
        )
      end

      it { should eq(other_patient) }
    end

    context "without an NHS number and an existing patient matching first name, date of birth and postcode" do
      let(:data) { valid_data.except("NHS_NUMBER") }

      let(:other_patient) do
        create(
          :patient,
          given_name:,
          date_of_birth: Date.parse(date_of_birth),
          address_postcode:,
          nhs_number:
        )
      end

      it { should eq(other_patient) }
    end

    context "without an NHS number and an existing patient matching last name, date of birth and postcode" do
      let(:data) { valid_data.except("NHS_NUMBER") }

      let(:other_patient) do
        create(
          :patient,
          family_name:,
          date_of_birth: Date.parse(date_of_birth),
          address_postcode:,
          nhs_number:
        )
      end

      it { should eq(other_patient) }
    end

    context "with an existing matching patient but different patient data" do
      let(:data) { valid_data }

      it "does not stage any changes as vaccs history data is potentially out of date" do
        create(:patient, nhs_number:, address_postcode: "CB1 1AA")
        expect(patient.pending_changes).to be_empty
      end
    end

    describe "#organisation" do
      subject(:cohort) { patient.organisation }

      let(:data) { valid_data }

      it { should be_nil }

      context "with an existing patient in the cohort" do
        let(:patient) { create(:patient, nhs_number:) }

        it { should eq(patient.organisation) }
      end
    end
  end

  describe "#location_name" do
    subject(:location_name) { immunisation_import_row.location_name }

    context "without data" do
      let(:data) { {} }

      it { should eq("Unknown") }
    end

    context "with a school session that exists" do
      let(:data) do
        valid_data.merge(
          "DATE_OF_VACCINATION" => session.dates.first.strftime("%Y%m%d"),
          "SESSION_ID" => session.id.to_s
        )
      end

      let(:session) { create(:session, organisation:, location:, programmes:) }

      it { should be_nil }
    end

    context "without a school URN" do
      let(:data) { valid_data.merge("SCHOOL_NAME" => "Waterloo Road") }

      it { should eq("Waterloo Road") }
    end

    context "without a school URN and a clinic exists" do
      let(:data) { valid_data.merge("SCHOOL_NAME" => "Waterloo Road") }

      before { create(:community_clinic, urn: nil) }

      it { should eq("Waterloo Road") }
    end

    context "with a known school and unknown care setting" do
      let(:data) do
        valid_data.merge(
          "SCHOOL_URN" => "123456",
          "SCHOOL_NAME" => "Waterloo Road"
        )
      end

      it { should eq("Waterloo Road") }
    end

    context "with a known school and no school name" do
      let(:data) { valid_data.merge("SCHOOL_URN" => "123456") }

      it { should eq("Waterloo Road") }
    end

    context "with a known school and community care setting" do
      let(:data) do
        valid_data.merge(
          "SCHOOL_URN" => "123456",
          "SCHOOL_NAME" => "Waterloo Road",
          "CARE_SETTING" => "2"
        )
      end

      it { should eq("Unknown") }
    end

    context "when home educated and community care setting" do
      let(:data) do
        valid_data.merge(
          "SCHOOL_URN" => "999999",
          "SCHOOL_NAME" => "",
          "CARE_SETTING" => "2"
        )
      end

      it { should eq("Unknown") }
    end

    context "when home educated and community care setting and a named clinic" do
      let(:data) do
        valid_data.merge(
          "SCHOOL_URN" => "999999",
          "SCHOOL_NAME" => "",
          "CARE_SETTING" => "2",
          "CLINIC_NAME" => "A Clinic"
        )
      end

      it { should eq("A Clinic") }
    end

    context "when home educated and unknown care setting" do
      let(:data) do
        valid_data.merge("SCHOOL_URN" => "999999", "SCHOOL_NAME" => "")
      end

      it { should eq("Unknown") }
    end

    context "when home educated and unknown care setting and a named clinic" do
      let(:data) do
        valid_data.merge(
          "SCHOOL_URN" => "999999",
          "SCHOOL_NAME" => "",
          "CLINIC_NAME" => "A Clinic"
        )
      end

      it { should eq("A Clinic") }
    end

    context "with an unknown school and school care setting" do
      let(:data) do
        valid_data.merge(
          "SCHOOL_URN" => "888888",
          "SCHOOL_NAME" => "Waterloo Road",
          "CARE_SETTING" => "1"
        )
      end

      it { should eq("Waterloo Road") }
    end

    context "with an unknown school and school care setting and a clinic name" do
      let(:data) do
        valid_data.merge(
          "SCHOOL_URN" => "888888",
          "SCHOOL_NAME" => "Waterloo Road",
          "CARE_SETTING" => "1",
          "CLINIC_NAME" => "A Clinic"
        )
      end

      it { should eq("Waterloo Road") }
    end

    context "with an unknown school and community care setting" do
      let(:data) do
        valid_data.merge(
          "SCHOOL_URN" => "888888",
          "SCHOOL_NAME" => "Waterloo Road",
          "CARE_SETTING" => "2"
        )
      end

      it { should eq("Unknown") }
    end

    context "with an unknown school and community care setting and a clinic name" do
      let(:data) do
        valid_data.merge(
          "SCHOOL_URN" => "888888",
          "SCHOOL_NAME" => "Waterloo Road",
          "CARE_SETTING" => "2",
          "CLINIC_NAME" => "A Clinic"
        )
      end

      it { should eq("A Clinic") }
    end

    context "with an unknown school and unknown care setting" do
      let(:data) do
        valid_data.merge(
          "SCHOOL_URN" => "888888",
          "SCHOOL_NAME" => "Waterloo Road"
        )
      end

      it { should eq("Waterloo Road") }
    end

    context "with an unknown school and unknown care setting and a clinic name" do
      let(:data) do
        valid_data.merge(
          "SCHOOL_URN" => "888888",
          "SCHOOL_NAME" => "Waterloo Road",
          "CLINIC_NAME" => "A Clinic"
        )
      end

      it { should eq("A Clinic") }
    end
  end

  describe "#dose_sequence" do
    subject(:dose_sequence) { immunisation_import_row.dose_sequence }

    let(:programmes) { [create(:programme, :hpv)] }

    context "without a value and for HPV" do
      let(:data) { { "PROGRAMME" => "HPV" } }

      it { should eq(1) }
    end

    context "without a value and for Td/IPV" do
      let(:data) { { "PROGRAMME" => "3-in-1" } }

      it { should be_nil }
    end

    context "without a value and for MenACWY" do
      let(:data) { { "PROGRAMME" => "MenACWY" } }

      it { should be_nil }
    end

    context "with an invalid value" do
      let(:data) { { "PROGRAMME" => "HPV", "DOSE_SEQUENCE" => "abc" } }

      it { should be_nil }
    end

    context "with a valid value" do
      let(:data) { { "PROGRAMME" => "HPV", "DOSE_SEQUENCE" => "1" } }

      it { should eq(1) }
    end

    %w[1P 2P 3P].each_with_index do |value, index|
      context "with an HPV special value of #{value}" do
        let(:programmes) { [create(:programme, :hpv)] }

        let(:data) { { "PROGRAMME" => "HPV", "DOSE_SEQUENCE" => value } }

        it { should eq(index + 1) }
      end
    end

    %w[1P 1B 2B].each_with_index do |value, index|
      context "with a MenACWY special value of #{value}" do
        let(:programmes) { [create(:programme, :menacwy)] }

        let(:data) { { "PROGRAMME" => "MenACWY", "DOSE_SEQUENCE" => value } }

        it { should eq(index + 1) }
      end
    end

    %w[1P 2P 3P 1B 2B].each_with_index do |value, index|
      context "with a Td/IPV special value of #{value}" do
        let(:programmes) { [create(:programme, :td_ipv)] }

        let(:data) { { "PROGRAMME" => "Td/IPV", "DOSE_SEQUENCE" => value } }

        it { should eq(index + 1) }
      end
    end
  end

  describe "#performed_by_user" do
    subject(:performed_by_user) { immunisation_import_row.performed_by_user }

    context "without a value" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with a value" do
      let(:data) { { "PERFORMING_PROFESSIONAL_EMAIL" => "nurse@example.com" } }

      context "and a user that doesn't exist" do
        it { should be_nil }
      end

      context "and a user that does exist" do
        let!(:user) { create(:user, email: "nurse@example.com") }

        it { should eq(user) }
      end
    end
  end

  describe "#to_vaccination_record" do
    subject(:vaccination_record) do
      immunisation_import_row.to_vaccination_record
    end

    let(:data) { valid_data }

    it "has a vaccinator" do
      expect(vaccination_record.performed_by).to have_attributes(
        given_name: "John",
        family_name: "Smith"
      )
    end

    it "sets the administered at time" do
      expect(vaccination_record.performed_at).to eq(
        Time.new(2024, 1, 1, 0, 0, 0, "+00:00")
      )
    end

    context "with a daylight saving time date" do
      let(:data) { valid_data.merge("DATE_OF_VACCINATION" => "20230901") }

      it "sets the administered at time" do
        expect(vaccination_record.performed_at).to eq(
          Time.new(2023, 9, 1, 0, 0, 0, "+01:00")
        )
      end
    end

    context "with an Excel-exported-to-CSV date format" do
      let(:data) { valid_data.merge("DATE_OF_VACCINATION" => "01/09/2023") }

      it "parses the date and sets the administered at time" do
        expect(vaccination_record.performed_at).to eq(
          Time.new(2023, 9, 1, 0, 0, 0, "+01:00")
        )
      end
    end

    context "with an ISO 8601 date format" do
      let(:data) { valid_data.merge("DATE_OF_VACCINATION" => "2023-09-01") }

      it "parses the date and sets the administered at time" do
        expect(vaccination_record.performed_at).to eq(
          Time.new(2023, 9, 1, 0, 0, 0, "+01:00")
        )
      end
    end

    context "with a time of vaccination" do
      let(:data) { valid_data.merge("TIME_OF_VACCINATION" => "10:30:25") }

      it "sets the administered at time" do
        expect(vaccination_record.performed_at).to eq(
          Time.new(2024, 1, 1, 10, 30, 25, "+00:00")
        )
      end
    end

    context "with a time of vaccination without seconds" do
      let(:data) { valid_data.merge("TIME_OF_VACCINATION" => "1030") }

      it "sets the administered at time" do
        expect(vaccination_record.performed_at).to eq(
          Time.new(2024, 1, 1, 10, 30, 0, "+00:00")
        )
      end
    end

    context "with an existing vaccination record" do
      let!(:existing_vaccination_record) do
        create(
          :vaccination_record,
          programme: programmes.first,
          session: create(:session, organisation:, programmes:)
        )
      end

      let(:data) do
        valid_data.merge("UUID" => existing_vaccination_record.uuid)
      end

      it { should_not be_nil }
      it { should eq(existing_vaccination_record) }
    end

    context "with notes" do
      let(:data) { valid_data.merge("NOTES" => "Some notes.") }

      it "sets the notes" do
        expect(vaccination_record.notes).to eq("Some notes.")
      end
    end
  end

  describe "#batch" do
    subject(:batch) { immunisation_import_row.to_vaccination_record.batch }

    let(:data) { valid_data }

    it { should be_archived }

    context "without a vaccine" do
      let(:data) { valid_data.merge("VACCINE_GIVEN" => "") }

      it { should be_nil }
    end

    context "without a batch number or expiry date" do
      let(:data) do
        valid_data.merge("BATCH_NUMBER" => "", "BATCH_EXPIRY_DATE" => "")
      end

      it { should be_nil }
    end
  end
end
