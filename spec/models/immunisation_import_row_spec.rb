# frozen_string_literal: true

describe ImmunisationImportRow do
  subject(:immunisation_import_row) do
    described_class.new(data:, organisation:)
  end

  let(:programme) { create(:programme, :flu) }
  let(:organisation) do
    create(:organisation, ods_code: "abc", programmes: [programme])
  end

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
      "VACCINE_GIVEN" => "AstraZeneca Fluenz Tetra LAIV",
      "ANATOMICAL_SITE" => "nasal",
      "PERFORMING_PROFESSIONAL_FORENAME" => "John",
      "PERFORMING_PROFESSIONAL_SURNAME" => "Smith"
    )
  end
  let(:valid_hpv_data) do
    valid_common_data.deep_dup.merge(
      "VACCINE_GIVEN" => "Gardasil9",
      "ANATOMICAL_SITE" => "Left Upper Arm",
      "DOSE_SEQUENCE" => "1",
      "CARE_SETTING" => "1"
    )
  end
  let(:valid_data) { valid_flu_data }

  let!(:location) { create(:school, urn: "123456") }

  describe "validations" do
    context "with an empty row" do
      let(:data) { {} }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:administered]).to include(
          /You need to record whether the child was vaccinated or not/
        )
        expect(immunisation_import_row.errors[:performed_ods_code]).to include(
          "Enter an organisation code."
        )
      end
    end

    context "when missing fields" do
      let(:data) { { "VACCINATED" => "Y" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:batch_expiry_date]).to eq(
          ["Enter a batch expiry date."]
        )
        expect(immunisation_import_row.errors[:batch_number]).to eq(
          ["Enter a batch number."]
        )
        expect(immunisation_import_row.errors[:delivery_site]).to eq(
          ["Enter an anatomical site."]
        )
        expect(immunisation_import_row.errors[:patient_date_of_birth]).to eq(
          ["Enter a date of birth in the correct format."]
        )
        expect(immunisation_import_row.errors[:patient_gender_code]).to eq(
          ["Enter a gender or gender code."]
        )
        expect(immunisation_import_row.errors[:patient_postcode]).to eq(
          ["Enter a valid postcode, such as SW1A 1AA"]
        )
        expect(immunisation_import_row.errors[:performed_ods_code]).to eq(
          ["Enter an organisation code."]
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
        expect(immunisation_import_row.errors[:vaccine_given]).to eq(
          ["Enter a valid vaccine, eg Gardasil9."]
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

    context "when vaccinated and a reason not given" do
      let(:data) do
        { "VACCINATED" => "Y", "REASON_NOT_VACCINATED" => "unwell" }
      end

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:reason]).to eq(["must be blank"])
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

      context "when importing for the current academic year" do
        let(:data) do
          { "DATE_OF_VACCINATION" => "#{Date.current.academic_year}0901" }
        end

        it { should include(/current session/) }
      end

      context "when importing for a different academic year" do
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
      let(:programme) { create(:programme, :hpv) }

      let(:data) { { "VACCINE_GIVEN" => "Gardasil9", "DOSE_SEQUENCE" => "4" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:dose_sequence]).to include(
          /must be less than/
        )
      end
    end

    context "vaccination in this academic year and no organisation provided" do
      let(:data) do
        { "DATE_OF_VACCINATION" => "#{Date.current.academic_year}0901" }
      end

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:performed_ods_code]).to eq(
          ["Enter an organisation code."]
        )
      end
    end

    context "vaccination in this academic year, no vaccinator details provided" do
      let(:data) do
        valid_data.except(
          "PERFORMING_PROFESSIONAL_EMAIL",
          "PERFORMING_PROFESSIONAL_FORENAME",
          "PERFORMING_PROFESSIONAL_SURNAME"
        ).merge(
          "DATE_OF_VACCINATION" => "#{Date.current.academic_year}0901",
          "VACCINATED" => "Y"
        )
      end

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

    context "vaccination in this academic year, vaccinator email not provided but forename and surname are" do
      let(:data) do
        valid_data.except("PERFORMING_PROFESSIONAL_EMAIL").merge(
          "PERFORMING_PROFESSIONAL_FORENAME" => "John",
          "PERFORMING_PROFESSIONAL_SURNAME" => "Smith",
          "DATE_OF_VACCINATION" => "#{Date.current.academic_year}0901",
          "VACCINATED" => "Y"
        )
      end

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:performed_by_user]).to include(
          "Enter a valid email address"
        )
      end
    end

    context "HPV vaccination in previous academic year, no vaccinator details provided" do
      let(:programme) { create(:programme, :hpv) }

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

    context "vaccination in this academic year, with a delivery site that is not appropriate for HPV" do
      let(:programme) { create(:programme, :hpv) }

      let(:data) do
        valid_hpv_data.merge(
          "ANATOMICAL_SITE" => "nasal",
          "VACCINATED" => "Y",
          "VACCINE_GIVEN" => "Gardasil9",
          "DATE_OF_VACCINATION" => "#{Date.current.academic_year}0901"
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
      let(:programme) { create(:programme, :hpv) }

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

    context "vaccination in this academic year, with a delivery site that is not appropriate for flu" do
      let(:programme) { create(:programme, :flu) }

      let(:data) do
        {
          "ANATOMICAL_SITE" => "left buttock",
          "VACCINATED" => "Y",
          "VACCINE_GIVEN" => "AstraZeneca Fluenz Tetra LAIV",
          "DATE_OF_VACCINATION" => "#{Date.current.academic_year}0901"
        }
      end

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:delivery_site]).to eq(
          ["Enter a anatomical site that is appropriate for the vaccine."]
        )
      end
    end

    context "with valid fields for Flu" do
      let(:programme) { create(:programme, :flu) }

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
      let(:programme) { create(:programme, :hpv) }

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

  describe "#session" do
    subject(:session) { immunisation_import_row.session }

    context "without data" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "in a previous academic year" do
      let(:data) { valid_data }

      it { should be_nil }
    end

    context "in a current academic year" do
      let(:date_of_vaccination) { Date.new(Date.current.academic_year, 9, 1) }

      context "when at school" do
        let(:school_session) do
          create(
            :session,
            location:,
            date: date_of_vaccination,
            organisation:,
            programme:
          )
        end

        let(:data) do
          valid_data.merge(
            "DATE_OF_VACCINATION" => date_of_vaccination.strftime("%Y%m%d")
          )
        end

        it { should eq(school_session) }
      end

      context "when home educated and community care setting" do
        let(:clinic) do
          create(:community_clinic, name: "A Clinic", organisation:)
        end

        let(:data) do
          valid_data.merge(
            "SCHOOL_URN" => "999999",
            "SCHOOL_NAME" => "",
            "CARE_SETTING" => "2",
            "CLINIC_NAME" => clinic.name,
            "DATE_OF_VACCINATION" => date_of_vaccination.strftime("%Y%m%d"),
            "PERFORMING_PROFESSIONAL_EMAIL" => vaccinator.email
          )
        end

        before do
          create(
            :session_date,
            value: date_of_vaccination,
            session: organisation.generic_clinic_session
          )
        end

        it { should eq(organisation.generic_clinic_session) }
      end

      context "when home educated and unknown care setting" do
        let(:data) do
          valid_data.merge(
            "SCHOOL_URN" => "999999",
            "SCHOOL_NAME" => "",
            "DATE_OF_VACCINATION" => date_of_vaccination.strftime("%Y%m%d")
          )
        end

        before do
          create(
            :session_date,
            value: date_of_vaccination,
            session: organisation.generic_clinic_session
          )
        end

        it { should eq(organisation.generic_clinic_session) }
      end

      context "with an unknown school and school care setting" do
        let(:data) do
          valid_data.merge(
            "SCHOOL_URN" => "888888",
            "SCHOOL_NAME" => "Waterloo Road",
            "CARE_SETTING" => "1",
            "DATE_OF_VACCINATION" => date_of_vaccination.strftime("%Y%m%d")
          )
        end

        before do
          create(
            :session_date,
            value: date_of_vaccination,
            session: organisation.generic_clinic_session
          )
        end

        it { should eq(organisation.generic_clinic_session) }
      end

      context "with an unknown school and community care setting" do
        let(:data) do
          valid_data.merge(
            "SCHOOL_URN" => "888888",
            "SCHOOL_NAME" => "Waterloo Road",
            "CARE_SETTING" => "2",
            "DATE_OF_VACCINATION" => date_of_vaccination.strftime("%Y%m%d")
          )
        end

        before do
          create(
            :session_date,
            value: date_of_vaccination,
            session: organisation.generic_clinic_session
          )
        end

        it { should eq(organisation.generic_clinic_session) }
      end

      context "with an unknown school and unknown case setting" do
        let(:data) do
          valid_data.merge(
            "SCHOOL_URN" => "888888",
            "SCHOOL_NAME" => "Waterloo Road",
            "DATE_OF_VACCINATION" => date_of_vaccination.strftime("%Y%m%d")
          )
        end

        before do
          create(
            :session_date,
            value: date_of_vaccination,
            session: organisation.generic_clinic_session
          )
        end

        it { should eq(organisation.generic_clinic_session) }
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
      let(:data) { valid_data }

      before do
        create(
          :session,
          organisation:,
          location:,
          date: Date.new(2024, 1, 1),
          programme:
        )
      end

      it { should be_nil }
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

  describe "#administered" do
    subject(:administered) { immunisation_import_row.administered }

    context "without a vaccinated field" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with positive short vaccinated value" do
      let(:data) { { "VACCINATED" => "Y" } }

      it { should be(true) }
    end

    context "with positive long vaccinated value" do
      let(:data) { { "VACCINATED" => "Yes" } }

      it { should be(true) }
    end

    context "with negative short vaccinated value" do
      let(:data) { { "VACCINATED" => "N" } }

      it { should be(false) }
    end

    context "with negative long vaccinated value" do
      let(:data) { { "VACCINATED" => "No" } }

      it { should be(false) }
    end

    context "with an unknown vaccinated value" do
      let(:data) { { "VACCINATED" => "Other" } }

      it { should be_nil }
    end

    context "with a vaccine given value" do
      let(:data) { { "VACCINE_GIVEN" => "Vaccine" } }

      it { should be(true) }
    end
  end

  describe "#batch_expiry_date" do
    subject(:batch_expiry_date) { immunisation_import_row.batch_expiry_date }

    context "without a value" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with an invalid value" do
      let(:data) { { "BATCH_EXPIRY_DATE" => "abc" } }

      it { should be_nil }
    end

    context "with a valid value" do
      let(:data) { { "BATCH_EXPIRY_DATE" => "20100101" } }

      it { should eq(Date.new(2010, 1, 1)) }
    end

    context "with an Excel-exported-to-CSV date format" do
      let(:data) { { "BATCH_EXPIRY_DATE" => "01/09/2027" } }

      it { should eq(Date.new(2027, 9, 1)) }
    end
  end

  describe "#batch_number" do
    subject(:batch_number) { immunisation_import_row.batch_number }

    context "without a value" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with a value" do
      let(:data) { { "BATCH_NUMBER" => "abc" } }

      it { should eq("abc") }
    end
  end

  describe "#reason" do
    subject(:reason) { immunisation_import_row.reason }

    context "without a reason" do
      let(:data) { { "VACCINATED" => "N" } }

      it { expect(immunisation_import_row).to be_invalid }
    end

    context "with an unknown reason" do
      let(:data) do
        { "VACCINATED" => "N", "REASON_NOT_VACCINATED" => "Unknown" }
      end

      it { expect(immunisation_import_row).to be_invalid }
    end

    {
      "refused" => :refused,
      "unwell" => :not_well,
      "vaccination contraindicated" => :contraindications,
      "already had elsewhere" => :already_had,
      "did not attend" => :absent_from_session,
      "absent from school" => :absent_from_school
    }.each do |input_reason, expected_enum|
      context "with reason '#{input_reason}'" do
        let(:data) do
          { "VACCINATED" => "N", "REASON_NOT_VACCINATED" => input_reason }
        end

        it { should eq(expected_enum) }
      end
    end
  end

  describe "#notes" do
    subject(:notes) { immunisation_import_row.notes }

    context "without notes" do
      let(:data) { {} }

      it { expect(notes).to be_nil }
    end

    context "with blank notes" do
      let(:data) { { "NOTES" => "" } }

      it { expect(notes).to be_nil }
    end

    context "with notes" do
      let(:data) { { "NOTES" => "Some notes." } }

      it { expect(notes).to eq("Some notes.") }
    end
  end

  describe "#delivery_method" do
    subject(:delivery_method) { immunisation_import_row.delivery_method }

    context "without an anatomical site" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with a nasal anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "nasal" } }

      it { should eq("nasal_spray") }
    end

    context "with a non-nasal anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "left thigh" } }

      it { should eq("intramuscular") }
    end

    context "with an unknown anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "other" } }

      it { should be_nil }
    end
  end

  describe "#delivery_site" do
    subject(:delivery_site) { immunisation_import_row.delivery_site }

    context "without an anatomical site" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with a left thigh anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "left thigh" } }

      it { should eq("left_thigh") }
    end

    context "with a right thigh anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "right thigh" } }

      it { should eq("right_thigh") }
    end

    context "with a left upper arm anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "left upper arm" } }

      it { should eq("left_arm_upper_position") }
    end

    context "with a right upper arm anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "right upper arm" } }

      it { should eq("right_arm_upper_position") }
    end

    context "with a left arm (upper position) anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "left arm (upper position)" } }

      it { should eq("left_arm_upper_position") }
    end

    context "with a right arm (upper position) anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "right arm (upper position)" } }

      it { should eq("right_arm_upper_position") }
    end

    context "with a left arm (lower position) anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "left arm (lower position)" } }

      it { should eq("left_arm_lower_position") }
    end

    context "with a right arm (lower position) anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "right arm (lower position)" } }

      it { should eq("right_arm_lower_position") }
    end

    context "with a left buttock anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "left buttock" } }

      it { should eq("left_buttock") }
    end

    context "with a right buttock anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "right buttock" } }

      it { should eq("right_buttock") }
    end

    context "with a nasal anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "nasal" } }

      it { should eq("nose") }
    end

    context "with an unknown anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "other" } }

      it { should be_nil }
    end
  end

  describe "#dose_sequence" do
    subject(:dose_sequence) { immunisation_import_row.dose_sequence }

    let(:programme) { create(:programme, :hpv) }

    context "without a value" do
      let(:data) { { "VACCINE_GIVEN" => "Gardasil9" } }

      it { should be_nil }
    end

    context "with an invalid value" do
      let(:data) do
        { "VACCINE_GIVEN" => "Gardasil9", "DOSE_SEQUENCE" => "abc" }
      end

      it { should be_nil }
    end

    context "with a valid value" do
      let(:data) { { "VACCINE_GIVEN" => "Gardasil9", "DOSE_SEQUENCE" => "1" } }

      it { should eq(1) }
    end
  end

  describe "#patient_date_of_birth" do
    subject(:patient_date_of_birth) do
      immunisation_import_row.patient_date_of_birth
    end

    context "without a value" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with a value" do
      let(:data) { { "PERSON_DOB" => "abc" } }

      it { should be_nil }
    end

    context "with a valid value" do
      let(:data) { { "PERSON_DOB" => "19900101" } }

      it { should eq(Date.new(1990, 1, 1)) }
    end

    context "with an Excel-exported-to-CSV date format" do
      let(:data) { { "PERSON_DOB" => "01/09/2023" } }

      it { should eq(Date.new(2023, 9, 1)) }
    end
  end

  describe "#patient_gender_code" do
    subject(:patient_gender_code) do
      immunisation_import_row.patient_gender_code
    end

    context "without a value" do
      let(:data) { {} }

      it { should be_nil }
    end

    shared_examples "with a value" do |key|
      context "with an unknown value" do
        let(:data) { { key => "unknown" } }

        it { should eq("unknown") }
      end

      context "with a 'not known' value" do
        let(:data) { { key => "Not Known" } }

        it { should eq("not_known") }
      end

      context "with a 'male' value" do
        let(:data) { { key => "Male" } }

        it { should eq("male") }
      end

      context "with a 'female' value" do
        let(:data) { { key => "Female" } }

        it { should eq("female") }
      end

      context "with a 'not specified' value" do
        let(:data) { { key => "Not Specified" } }

        it { should eq("not_specified") }
      end
    end

    include_examples "with a value", "PERSON_GENDER_CODE"
    include_examples "with a value", "PERSON_GENDER"
  end

  describe "#patient_postcode" do
    subject(:patient_postcode) { immunisation_import_row.patient_postcode }

    context "without a value" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with an invalid postcode" do
      let(:data) { { "PERSON_POSTCODE" => "abc" } }

      it { should eq("abc") }
    end

    context "with a valid postcode" do
      let(:data) { { "PERSON_POSTCODE" => "SW1 1AA" } }

      it { should eq("SW1 1AA") }
    end

    context "with a valid unformatted postcode" do
      let(:data) { { "PERSON_POSTCODE" => "sw11aa" } }

      it { should eq("SW1 1AA") }
    end
  end

  describe "#performed_ods_code" do
    subject(:performed_ods_code) { immunisation_import_row.performed_ods_code }

    context "without a value" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with a value" do
      let(:data) { { "ORGANISATION_CODE" => "abc" } }

      it { should eq("ABC") }
    end
  end

  describe "#time_of_vaccination" do
    subject(:time_of_vaccination) do
      immunisation_import_row.time_of_vaccination
    end

    let(:year) { Time.current.year }
    let(:month) { Time.current.month }
    let(:day) { Time.current.day }

    context "without a value" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with an invalid value" do
      let(:data) { { "TIME_OF_VACCINATION" => "abc" } }

      it { should be_nil }
    end

    context "with a HH:MM:SS value" do
      let(:data) { { "TIME_OF_VACCINATION" => "10:15:30" } }

      it { should eq(Time.zone.local(year, month, day, 10, 15, 30)) }
    end

    context "with a HHMMSS value" do
      let(:data) { { "TIME_OF_VACCINATION" => "101530" } }

      it { should eq(Time.zone.local(year, month, day, 10, 15, 30)) }
    end

    context "with a HH:MM value" do
      let(:data) { { "TIME_OF_VACCINATION" => "10:15" } }

      it { should eq(Time.zone.local(year, month, day, 10, 15, 0)) }
    end

    context "with a HHMM value" do
      let(:data) { { "TIME_OF_VACCINATION" => "1015" } }

      it { should eq(Time.zone.local(year, month, day, 10, 15, 0)) }
    end

    context "with a HH value" do
      let(:data) { { "TIME_OF_VACCINATION" => "10" } }

      it { should eq(Time.zone.local(year, month, day, 10, 0, 0)) }
    end
  end

  describe "#care_setting" do
    subject(:care_setting) { immunisation_import_row.care_setting }

    context "without a value" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with a valid value" do
      let(:data) { { "CARE_SETTING" => "1" } }

      it { should eq(1) }
    end

    context "with an invalid value" do
      let(:data) { { "CARE_SETTING" => "School" } }

      it { should be_nil }
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

  describe "#performed_by_given_name" do
    subject(:performed_by_given_name) do
      immunisation_import_row.performed_by_given_name
    end

    context "without a value" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with a value" do
      let(:data) { { "PERFORMING_PROFESSIONAL_FORENAME" => "John" } }

      it { should eq("John") }
    end
  end

  describe "#performed_by_family_name" do
    subject(:performed_by_family_name) do
      immunisation_import_row.performed_by_family_name
    end

    context "without a value" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with a value" do
      let(:data) { { "PERFORMING_PROFESSIONAL_SURNAME" => "Smith" } }

      it { should eq("Smith") }
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
        Time.new(2024, 1, 1, 12, 0, 0, "+00:00")
      )
    end

    context "with a daylight saving time date" do
      let(:data) { valid_data.merge("DATE_OF_VACCINATION" => "20230901") }

      it "sets the administered at time" do
        expect(vaccination_record.performed_at).to eq(
          Time.new(2023, 9, 1, 12, 0, 0, "+01:00")
        )
      end
    end

    context "with an Excel-exported-to-CSV date format" do
      let(:data) { valid_data.merge("DATE_OF_VACCINATION" => "01/09/2023") }

      it "parses the date and sets the administered at time" do
        expect(vaccination_record.performed_at).to eq(
          Time.new(2023, 9, 1, 12, 0, 0, "+01:00")
        )
      end
    end

    context "with an ISO 8601 date format" do
      let(:data) { valid_data.merge("DATE_OF_VACCINATION" => "2023-09-01") }

      it "parses the date and sets the administered at time" do
        expect(vaccination_record.performed_at).to eq(
          Time.new(2023, 9, 1, 12, 0, 0, "+01:00")
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
          programme:,
          session: create(:session, organisation:, programme:)
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
  end
end
