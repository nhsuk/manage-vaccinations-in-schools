# frozen_string_literal: true

describe ImmunisationImportRow do
  subject(:immunisation_import_row) do
    described_class.new(data: data_as_csv_row, team:)
  end

  # FIXME: Don't re-implement behaviour of `CSVParser`.
  let(:data_as_csv_row) do
    data.each_with_object({}) do |(key, value), hash|
      hash[
        key.strip.downcase.tr("-", "_").tr(" ", "_").to_sym
      ] = CSVParser::Field.new(value, nil, nil, key)
    end
  end

  let(:programmes) { [Programme.hpv] }
  let(:team) { create(:team, ods_code: "abc", programmes:) }

  let(:nhs_number) { "9990000018" }
  let(:given_name) { "Harry" }
  let(:family_name) { "Potter" }
  let(:date_of_birth) { "20120101" }
  let(:address_postcode) { "SW1A 1AA" }
  let(:vaccinator) { create(:user, team:) }
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
      "NHS_NUMBER" => nhs_number
    }
  end
  let(:valid_flu_data) do
    valid_common_data.deep_dup.merge(
      "ANATOMICAL_SITE" => "nasal",
      "BATCH_EXPIRY_DATE" => Date.tomorrow.iso8601,
      "DATE_OF_VACCINATION" => Date.current.iso8601,
      "PERFORMING_PROFESSIONAL_FORENAME" => "John",
      "PERFORMING_PROFESSIONAL_SURNAME" => "Smith",
      "PROGRAMME" => "Flu",
      "VACCINE_GIVEN" => "AstraZeneca Fluenz"
    )
  end
  let(:valid_hpv_data) do
    valid_common_data.deep_dup.merge(
      "ANATOMICAL_SITE" => "Left Upper Arm",
      "CARE_SETTING" => "1",
      "DATE_OF_VACCINATION" => "20240101",
      "DOSE_SEQUENCE" => "1",
      "PROGRAMME" => "HPV",
      "VACCINE_GIVEN" => "Gardasil9"
    )
  end
  let(:valid_data) { valid_hpv_data }

  let!(:location) { create(:school, urn: "123456", name: "Waterloo Road") }

  describe "validations" do
    context "with an empty row" do
      let(:data) { {} }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:base]).to contain_exactly(
          "<code>VACCINATED</code> is required",
          "<code>DATE_OF_VACCINATION</code> or <code>Event date</code> is required",
          "<code>PERSON_DOB</code> or <code>Date of birth</code> is required",
          "<code>PERSON_FORENAME</code> or <code>First name</code> is required",
          "<code>PERSON_GENDER_CODE</code>, <code>PERSON_GENDER</code> or <code>Sex</code> is required",
          "<code>PERSON_SURNAME</code> or <code>Surname</code> is required",
          "<code>PERSON_POSTCODE</code> or <code>Postcode</code> is required",
          "<code>PROGRAMME</code> or <code>Vaccination type</code> is required",
          "<code>REASON_NOT_VACCINATED</code> is required"
        )
      end
    end

    context "when missing VACCINATED but a vaccine has been given" do
      let(:data) { { "VACCINE_GIVEN" => "A vaccine" } }

      it "doesn't require a VACCINATED column" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:base]).not_to include(
          "<code>VACCINATED</code> is required"
        )
      end
    end

    context "when missing VACCINATED but a vaccination type has been given" do
      let(:data) { { "Vaccination type" => "HPV 1" } }

      it "doesn't require a VACCINATED column" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:base]).not_to include(
          "<code>VACCINATED</code> is required"
        )
      end
    end

    context "when missing fields" do
      let(:data) { { "VACCINATED" => "Y" } }

      it { should be_invalid }

      context "with an NHS number and missing fields" do
        let(:data) { { "VACCINATED" => "Y", "NHS_NUMBER" => nhs_number } }

        it "doesn't require a postcode" do
          expect(immunisation_import_row).to be_invalid
          expect(immunisation_import_row.errors[:base]).not_to include(
            "<code>PERSON_POSTCODE</code> is required"
          )
        end
      end
    end

    context "with an invalid vaccine" do
      let(:data) { { "VACCINATED" => "Y", "VACCINE_GIVEN" => "test" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors["VACCINE_GIVEN"]).to eq(
          ["This vaccine is not available in this session."]
        )
      end
    end

    context "with an invalid vaccine for the programme" do
      let(:data) do
        { "PROGRAMME" => "HPV", "VACCINE_GIVEN" => "AstraZeneca Fluenz" }
      end

      let(:programmes) { [Programme.flu, Programme.hpv] }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(
          immunisation_import_row.errors["VACCINE_GIVEN"]
        ).to contain_exactly("is not given in the HPV programme")
      end
    end

    context "without a vaccine" do
      let(:data) { valid_data.except("VACCINE_GIVEN") }

      it { should be_valid }
    end

    context "without a vaccine and recording offline" do
      let(:data) do
        valid_data.merge(
          "VACCINE_GIVEN" => "",
          "DATE_OF_VACCINATION" => "#{AcademicYear.current}0901",
          "SESSION_ID" => session.id.to_s
        )
      end

      let(:session) { create(:session, team:, programmes:) }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors["VACCINE_GIVEN"]).to eq(
          ["is required"]
        )
      end
    end

    context "with an invalid reason not vaccinated" do
      let(:data) do
        { "VACCINATED" => "N", "REASON_NOT_VACCINATED" => "unknown" }
      end

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors["REASON_NOT_VACCINATED"]).to eq(
          ["Enter a valid reason"]
        )
      end
    end

    context "with an invalid batch name" do
      let(:data) { { "VACCINATED" => "Y", "BATCH_NUMBER" => "[invalid]" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors["BATCH_NUMBER"]).to eq(
          ["must be only letters and numbers"]
        )
      end
    end

    context "with an invalid postcode" do
      let(:data) { { "PERSON_POSTCODE" => "ABC DEF" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors["PERSON_POSTCODE"]).to include(
          "Enter a valid postcode, such as SW1A 1AA."
        )
      end
    end

    context "with an invalid gender code" do
      let(:data) { { "PERSON_GENDER_CODE" => "10" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors["PERSON_GENDER_CODE"]).to eq(
          ["Enter a valid gender or gender code."]
        )
      end
    end

    context "with an invalid date of vaccination" do
      let(:data) { { "DATE_OF_VACCINATION" => "21000101" } }

      it { should be_invalid }
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
        expect(
          immunisation_import_row.errors["TIME_OF_VACCINATION"]
        ).to include("Enter a time in the past.")
      end
    end

    context "with a date of vaccination before the child was born" do
      around { |example| freeze_time { example.run } }

      let(:data) do
        { "PERSON_DOB" => "20100101", "DATE_OF_VACCINATION" => "20090101" }
      end

      it "has an error" do
        expect(immunisation_import_row).to be_invalid
        expect(
          immunisation_import_row.errors["DATE_OF_VACCINATION"]
        ).to include("The vaccination date is before the date of birth.")
      end
    end

    context "when vaccinated and a reason not given" do
      let(:data) do
        { "VACCINATED" => "Y", "REASON_NOT_VACCINATED" => "unwell" }
      end

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors["REASON_NOT_VACCINATED"]).to eq(
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
        expect(
          immunisation_import_row.errors["TIME_OF_VACCINATION"]
        ).to be_empty
      end
    end

    context "when date doesn't match an existing session" do
      subject(:errors) { immunisation_import_row.errors["DATE_OF_VACCINATION"] }

      before { immunisation_import_row.valid? }

      context "when importing for an existing session" do
        around { |example| travel_to(Date.new(2025, 9, 1)) { example.run } }

        let(:data) do
          {
            "DATE_OF_VACCINATION" => "20250902",
            "SESSION_ID" => session.id.to_s
          }
        end

        let(:session) { create(:session, team:, programmes:) }

        it do
          expect(errors).to include(
            "Enter a date that matches when the vaccination session took place."
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
        expect(immunisation_import_row.errors["TIME_OF_VACCINATION"]).to eq(
          ["Enter a time in the correct format."]
        )
      end
    end

    context "with an invalid NHS number" do
      let(:data) { { "NHS_NUMBER" => "TP01234567" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors["NHS_NUMBER"]).to eq(
          ["should be a valid NHS number with 10 characters"]
        )
      end
    end

    context "with an invalid patient date of birth" do
      let(:data) { { "PERSON_DOB" => "21000101" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors["PERSON_DOB"]).to eq(
          ["Enter a date of birth in the past."]
        )
      end
    end

    context "with clinic care setting" do
      let(:valid_clinic_data) do
        valid_data.merge(
          "CARE_SETTING" => "2",
          "DATE_OF_VACCINATION" => session.dates.first.strftime("%Y%m%d"),
          "SESSION_ID" => session.id.to_s,
          "ORGANISATION_CODE" => team.organisation.ods_code,
          "PERFORMING_PROFESSIONAL_EMAIL" => create(:user).email
        )
      end

      let(:session) { create(:session, team:, programmes:) }

      before { create(:community_clinic, name: "A clinic", team:) }

      context "with an existing community clinic" do
        let(:data) { valid_clinic_data.merge("CLINIC_NAME" => "A clinic") }

        it "is matching" do
          expect(immunisation_import_row).to be_valid
        end
      end

      context "with incorrect casing for an existing clinic" do
        let(:data) { valid_clinic_data.merge("CLINIC_NAME" => "a cLinIC") }

        it "is case insensitive" do
          expect(immunisation_import_row).to be_valid
        end
      end

      context "with a non-existent clinic" do
        let(:data) do
          valid_clinic_data.merge("CLINIC_NAME" => "A wrong clinic")
        end

        it "is invalid" do
          expect(immunisation_import_row).to be_invalid

          expect(
            immunisation_import_row.errors["CLINIC_NAME"]
          ).to contain_exactly("is not recognised")
        end
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
        expect(immunisation_import_row.errors[:base]).to include(
          "Two or more possible patients match the patient first name, last name, date of birth or postcode."
        )
      end
    end

    context "with an invalid dose sequence" do
      let(:programmes) { [Programme.hpv] }

      let(:data) { { "PROGRAMME" => "HPV", "DOSE_SEQUENCE" => "4" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors["DOSE_SEQUENCE"]).to include(
          /must be less than or equal to/
        )
      end
    end

    context "with an invalid session ID" do
      let(:data) { { "SESSION_ID" => "abc" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors["SESSION_ID"]).to include(
          "The session ID is not recognised. Download the offline spreadsheet and copy the session ID " \
            "for this row from there, or contact our support team."
        )
      end
    end

    context "with a session ID that doesn't exist" do
      let(:data) { { "SESSION_ID" => "123" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors["SESSION_ID"]).to include(
          "The session ID is not recognised. Download the offline spreadsheet and copy the session ID " \
            "for this row from there, or contact our support team."
        )
      end
    end

    context "vaccination in a session and no team provided" do
      let(:data) { { "SESSION_ID" => session.id.to_s } }

      let(:session) { create(:session, team:, programmes:) }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:base]).to include(
          "<code>ORGANISATION_CODE</code> is required"
        )
      end
    end

    context "vaccination in a session and invalid programme" do
      let(:data) do
        { "SESSION_ID" => session.id.to_s, "PROGRAMME" => "MenACWY" }
      end

      let(:programmes) { [Programme.hpv, Programme.menacwy] }
      let(:session) { create(:session, team:, programmes: [programmes.first]) }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors["PROGRAMME"]).to eq(
          ["This programme is not available in this session."]
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
          "DATE_OF_VACCINATION" => "#{AcademicYear.current}0901",
          "VACCINATED" => "Y",
          "SESSION_ID" => session.id.to_s
        )
      end

      let(:session) { create(:session, team:, programmes:) }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:base]).to include(
          "<code>PERFORMING_PROFESSIONAL_EMAIL</code> is required"
        )
      end
    end

    context "vaccination in a session, vaccinator email not provided but forename and surname are" do
      let(:data) do
        valid_data.except("PERFORMING_PROFESSIONAL_EMAIL").merge(
          "PERFORMING_PROFESSIONAL_FORENAME" => "John",
          "PERFORMING_PROFESSIONAL_SURNAME" => "Smith",
          "DATE_OF_VACCINATION" => "#{AcademicYear.current}0901",
          "VACCINATED" => "Y",
          "SESSION_ID" => session.id.to_s
        )
      end

      let(:session) { create(:session, team:, programmes:) }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:base]).to include(
          "<code>PERFORMING_PROFESSIONAL_EMAIL</code> is required"
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

      let(:programmes) { [Programme.menacwy] }
      let(:session) { create(:session, team:, programmes:) }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors["DOSE_SEQUENCE"]).to eq(
          ["Do not provide a dose sequence for this programme (leave blank)."]
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

      let(:programmes) { [Programme.td_ipv] }
      let(:session) { create(:session, team:, programmes:) }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors["DOSE_SEQUENCE"]).to eq(
          ["Do not provide a dose sequence for this programme (leave blank)."]
        )
      end
    end

    context "HPV vaccination in previous academic year, no vaccinator details provided" do
      let(:programmes) { [Programme.hpv] }

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
        expect(
          immunisation_import_row.errors["PERFORMING_PROFESSIONAL_EMAIL"]
        ).to include("Enter a valid email address")
      end
    end

    context "Flu vaccination in previous academic year" do
      let(:programmes) { [Programme.flu] }

      let(:data) { valid_flu_data.merge("DATE_OF_VACCINATION" => "20240101") }

      it "is invalid" do
        expect(immunisation_import_row).to be_invalid
        expect(
          immunisation_import_row.errors["DATE_OF_VACCINATION"]
        ).to contain_exactly("must be in the current academic year")
      end
    end

    context "Flu vaccination in previous academic year, no vaccinator details provided" do
      let(:programmes) { [Programme.flu] }

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
      let(:programmes) { [Programme.hpv] }
      let(:session) { create(:session, team:, programmes:) }

      let(:data) do
        valid_hpv_data.merge(
          "ANATOMICAL_SITE" => "nasal",
          "VACCINATED" => "Y",
          "VACCINE_GIVEN" => "Gardasil9",
          "DATE_OF_VACCINATION" => "#{AcademicYear.current}0901",
          "SESSION_ID" => session.id.to_s
        )
      end

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors["ANATOMICAL_SITE"]).to eq(
          ["Enter a anatomical site that is appropriate for the vaccine."]
        )
      end
    end

    context "vaccination in a previous academic year, with a delivery site that's typically not appropriate for HPV" do
      let(:programmes) { [Programme.hpv] }

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
        expect(immunisation_import_row.errors["ANATOMICAL_SITE"]).to be_empty
      end
    end

    context "vaccination in a session, with a delivery site that is not appropriate for flu" do
      let(:programmes) { [Programme.flu] }
      let(:session) { create(:session, team:, programmes:) }

      let(:data) do
        {
          "ANATOMICAL_SITE" => "left buttock",
          "VACCINATED" => "Y",
          "PROGRAMME" => "Flu",
          "VACCINE_GIVEN" => "AstraZeneca Fluenz",
          "DATE_OF_VACCINATION" => "#{AcademicYear.current}0901",
          "SESSION_ID" => session.id.to_s
        }
      end

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors["ANATOMICAL_SITE"]).to eq(
          ["Enter a anatomical site that is appropriate for the vaccine."]
        )
      end
    end

    context "vaccination in a session without a batch" do
      let(:programmes) { [Programme.flu] }

      let(:data) do
        {
          "VACCINATED" => "Y",
          "PROGRAMME" => "Flu",
          "DATE_OF_VACCINATION" => "#{AcademicYear.current}0901",
          "SESSION_ID" => session.id.to_s
        }
      end

      let(:session) { create(:session, team:, programmes:) }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:base]).to include(
          "<code>BATCH_EXPIRY_DATE</code> is required"
        )
        expect(immunisation_import_row.errors[:base]).to include(
          "<code>BATCH_NUMBER</code> or <code>Vaccination batch number</code> is required"
        )
      end
    end

    context "vaccination in a session where name-like fields have length greater than 300" do
      let(:invalid_name_length) { "a" * 301 }
      let(:data) do
        {
          "VACCINATED" => "Y",
          "BATCH_NUMBER" => invalid_name_length,
          "CLINIC_NAME" => invalid_name_length,
          "PERSON_FORENAME" => invalid_name_length,
          "PERSON_SURNAME" => invalid_name_length,
          "SCHOOL_NAME" => invalid_name_length
        }
      end

      it "has errors" do
        expect(immunisation_import_row).to be_invalid

        expect(immunisation_import_row.errors["BATCH_NUMBER"]).to include(
          "must be at most 100 characters long"
        )
        expect(immunisation_import_row.errors["CLINIC_NAME"]).to include(
          "is greater than 300 characters long"
        )
        expect(immunisation_import_row.errors["PERSON_FORENAME"]).to include(
          "is greater than 300 characters long"
        )
        expect(immunisation_import_row.errors["PERSON_SURNAME"]).to include(
          "is greater than 300 characters long"
        )
        expect(immunisation_import_row.errors["SCHOOL_NAME"]).to include(
          "is greater than 300 characters long"
        )
      end
    end

    context "batch number fewer than 2 characters" do
      let(:data) { { "VACCINATED" => "Y", "BATCH_NUMBER" => "a" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid

        expect(immunisation_import_row.errors["BATCH_NUMBER"]).to include(
          "must be at least 2 characters long"
        )
      end
    end

    context "vaccination in a session without a delivery site" do
      let(:programmes) { [Programme.flu] }

      let(:data) do
        {
          "VACCINATED" => "Y",
          "PROGRAMME" => "Flu",
          "DATE_OF_VACCINATION" => "#{AcademicYear.current}0901",
          "SESSION_ID" => session.id.to_s
        }
      end

      let(:session) { create(:session, team:, programmes:) }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:base]).to include(
          "<code>ANATOMICAL_SITE</code> is required"
        )
      end
    end

    context "vaccination in a session, but UUID matches a record sourced from NHS immunisations API" do
      let(:data) do
        {
          "VACCINATED" => "Y",
          "PROGRAMME" => "Flu",
          "SESSION_ID" => 1,
          "DATE_OF_VACCINATION" => "#{AcademicYear.current}0901",
          "UUID" => "12345678-1234-1234-1234-123456789abc"
        }
      end

      before do
        create(
          :vaccination_record,
          programme: Programme.flu,
          uuid: "12345678-1234-1234-1234-123456789abc",
          source: :nhs_immunisations_api,
          nhs_immunisations_api_identifier_system: "ABC",
          nhs_immunisations_api_identifier_value: "123"
        )
      end

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors["SESSION_ID"]).to eq(
          [
            "A session ID cannot be provided for this record; " \
              "this record was sourced from an external source."
          ]
        )
      end
    end

    context "with valid fields for Flu" do
      let(:programmes) { [Programme.flu] }

      let(:data) { valid_flu_data }

      it { should be_valid }

      context "with a performing profession email provided as well" do
        before { data["PERFORMING_PROFESSIONAL_EMAIL"] = create(:user).email }

        it { should be_valid }

        it "ignores the performing professional fields" do
          expect(
            immunisation_import_row.to_vaccination_record.performed_by_given_name
          ).to be_nil
          expect(
            immunisation_import_row.to_vaccination_record.performed_by_family_name
          ).to be_nil
        end
      end
    end

    context "with valid fields for HPV" do
      let(:programmes) { [Programme.hpv] }

      let(:data) { valid_hpv_data }

      it { should be_valid }
    end
  end

  describe "#to_vaccination_record" do
    subject(:vaccination_record) do
      immunisation_import_row.to_vaccination_record
    end

    let(:data) { valid_data }

    let(:not_vaccinated_data) do
      valid_data.merge(
        "VACCINATED" => "N",
        "BATCH_EXPIRY_DATE" => "",
        "BATCH_NUMBER" => "",
        "ANATOMICAL_SITE" => ""
      )
    end

    it { should be_administered }

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

    context "with the flu programme" do
      let(:programmes) { [Programme.flu] }

      let(:data) { valid_flu_data }

      it "has a vaccinator" do
        expect(vaccination_record.performed_by).to have_attributes(
          given_name: "John",
          family_name: "Smith"
        )
      end
    end

    context "without a vaccine" do
      let(:data) { valid_data.except("VACCINE_GIVEN") }

      it "doesn't set a vaccine" do
        expect(vaccination_record.vaccine).to be_nil
      end

      it "does set a programme" do
        expect(vaccination_record.programme).not_to be_nil
      end
    end

    context "with an existing vaccination record" do
      let!(:existing_vaccination_record) do
        create(
          :vaccination_record,
          programme: programmes.first,
          session: create(:session, team:, programmes:)
        )
      end

      let(:data) do
        valid_data.merge("UUID" => existing_vaccination_record.uuid)
      end

      it { should_not be_nil }
      it { should eq(existing_vaccination_record) }

      context "and the record has been previously discarded" do
        before { existing_vaccination_record.discard! }

        it "stages changes discarded at to nil" do
          expect(vaccination_record.pending_changes["discarded_at"]).to be_nil
        end
      end
    end

    describe "#batch" do
      subject(:batch) { vaccination_record.batch }

      let(:data) { valid_data }

      it { should be_archived }

      its(:team) { should be_nil }

      context "without a vaccine" do
        before { data.delete("VACCINE_GIVEN") }

        it { should be_nil }
      end

      context "without a batch number or expiry date" do
        before do
          data.delete("BATCH_NUMBER")
          data.delete("BATCH_EXPIRY_DATE")
        end

        it { should be_nil }
      end

      context "when recording offline" do
        let(:data) do
          valid_data.merge(
            "DATE_OF_VACCINATION" => session.dates.first.strftime("%Y%m%d"),
            "SESSION_ID" => session.id.to_s,
            "ORGANISATION_CODE" => team.organisation.ods_code,
            "PERFORMING_PROFESSIONAL_EMAIL" => create(:user).email,
            "DOSE_SEQUENCE" => "1"
          )
        end

        let(:session) { create(:session, team:, programmes:) }

        its(:team) { should eq(session.team) }
      end
    end

    describe "#delivery_method" do
      subject { vaccination_record.delivery_method }

      context "with a nasal anatomical site" do
        let(:data) { valid_data.merge("ANATOMICAL_SITE" => "nasal") }

        it { should eq("nasal_spray") }
      end

      context "with a non-nasal anatomical site" do
        let(:data) { valid_data.merge("ANATOMICAL_SITE" => "left thigh") }

        it { should eq("intramuscular") }
      end
    end

    describe "#delivery_site" do
      subject { vaccination_record.delivery_site }

      context "with a left thigh anatomical site" do
        let(:data) { valid_data.merge("ANATOMICAL_SITE" => "left thigh") }

        it { should eq("left_thigh") }
      end

      context "with a right thigh anatomical site" do
        let(:data) { valid_data.merge("ANATOMICAL_SITE" => "right thigh") }

        it { should eq("right_thigh") }
      end

      context "with a left upper arm anatomical site" do
        let(:data) { valid_data.merge("ANATOMICAL_SITE" => "left upper arm") }

        it { should eq("left_arm_upper_position") }
      end

      context "with a right upper arm anatomical site" do
        let(:data) { valid_data.merge("ANATOMICAL_SITE" => "right upper arm") }

        it { should eq("right_arm_upper_position") }
      end

      context "with a left arm (upper position) anatomical site" do
        let(:data) do
          valid_data.merge("ANATOMICAL_SITE" => "left arm (upper position)")
        end

        it { should eq("left_arm_upper_position") }
      end

      context "with a right arm (upper position) anatomical site" do
        let(:data) do
          valid_data.merge("ANATOMICAL_SITE" => "right arm (upper position)")
        end

        it { should eq("right_arm_upper_position") }
      end

      context "with a left arm (lower position) anatomical site" do
        let(:data) do
          valid_data.merge("ANATOMICAL_SITE" => "left arm (lower position)")
        end

        it { should eq("left_arm_lower_position") }
      end

      context "with a right arm (lower position) anatomical site" do
        let(:data) do
          valid_data.merge("ANATOMICAL_SITE" => "right arm (lower position)")
        end

        it { should eq("right_arm_lower_position") }
      end

      context "with a left buttock anatomical site" do
        let(:data) { valid_data.merge("ANATOMICAL_SITE" => "left buttock") }

        it { should eq("left_buttock") }
      end

      context "with a right buttock anatomical site" do
        let(:data) { valid_data.merge("ANATOMICAL_SITE" => "right buttock") }

        it { should eq("right_buttock") }
      end

      context "with a nasal anatomical site" do
        let(:data) { valid_data.merge("ANATOMICAL_SITE" => "nasal") }

        it { should eq("nose") }
      end
    end

    describe "#dose_sequence" do
      subject { vaccination_record.dose_sequence }

      context "without a value and for HPV" do
        let(:programmes) { [Programme.hpv] }

        let(:data) do
          valid_data.merge(
            "PROGRAMME" => "HPV",
            "VACCINE_GIVEN" => "Gardasil9",
            "DOSE_SEQUENCE" => ""
          )
        end

        it { should eq(1) }
      end

      context "without a value and for Td/IPV" do
        let(:programmes) { [Programme.td_ipv] }

        let(:data) do
          valid_data.merge(
            "PROGRAMME" => "3-in-1",
            "VACCINE_GIVEN" => "Revaxis",
            "DOSE_SEQUENCE" => ""
          )
        end

        it { should be_nil }
      end

      context "without a value and for MenACWY" do
        let(:programmes) { [Programme.menacwy] }

        let(:data) do
          valid_data.merge(
            "PROGRAMME" => "MenACWY",
            "VACCINE_GIVEN" => "MenQuadfi",
            "DOSE_SEQUENCE" => ""
          )
        end

        it { should be_nil }
      end

      context "with an invalid value" do
        let(:programmes) { [Programme.hpv] }

        let(:data) do
          valid_data.merge(
            "PROGRAMME" => "HPV",
            "VACCINE_GIVEN" => "Gardasil9",
            "DOSE_SEQUENCE" => "abc"
          )
        end

        it { expect(immunisation_import_row).to be_invalid }
      end

      context "with an invalid value and no programme" do
        let(:programmes) { [Programme.hpv] }

        let(:data) do
          valid_data.merge(
            "PROGRAMME" => "Unknown",
            "VACCINE_GIVEN" => "Unknown",
            "DOSE_SEQUENCE" => "abc"
          )
        end

        it "has errors about the programme but not the dose sequence" do
          expect(immunisation_import_row).to be_invalid
          expect(immunisation_import_row.errors["PROGRAMME"]).to eq(
            ["This programme is not available in this session."]
          )
          expect(immunisation_import_row.errors["DOSE_SEQUENCE"]).to be_empty
        end
      end

      context "with a valid value" do
        let(:programmes) { [Programme.hpv] }

        let(:data) do
          valid_data.merge(
            "PROGRAMME" => "HPV",
            "VACCINE_GIVEN" => "Gardasil9",
            "DOSE_SEQUENCE" => "1"
          )
        end

        it { should eq(1) }
      end

      %w[1P 2P 3P].each_with_index do |value, index|
        context "with an HPV special value of #{value}" do
          let(:programmes) { [Programme.hpv] }

          let(:data) do
            valid_data.merge(
              "PROGRAMME" => "HPV",
              "VACCINE_GIVEN" => "Gardasil9",
              "DOSE_SEQUENCE" => value
            )
          end

          it { should eq(index + 1) }
        end
      end

      %w[1P 1B 2B].each_with_index do |value, index|
        context "with a MenACWY special value of #{value}" do
          let(:programmes) { [Programme.menacwy] }

          let(:data) do
            valid_data.merge(
              "PROGRAMME" => "MenACWY",
              "VACCINE_GIVEN" => "MenQuadfi",
              "DOSE_SEQUENCE" => value
            )
          end

          it { should eq(index + 1) }
        end
      end

      %w[1P 2P 3P 1B 2B].each_with_index do |value, index|
        context "with a Td/IPV special value of #{value}" do
          let(:programmes) { [Programme.td_ipv] }

          let(:data) do
            valid_data.merge(
              "PROGRAMME" => "Td/IPV",
              "VACCINE_GIVEN" => "Revaxis",
              "DOSE_SEQUENCE" => value
            )
          end

          it { should eq(index + 1) }
        end
      end
    end

    describe "#location_name" do
      subject { vaccination_record.location_name }

      let(:valid_data) { valid_hpv_data.except("CARE_SETTING") }

      context "with a school session that exists" do
        let(:data) do
          valid_data.merge(
            "DATE_OF_VACCINATION" => session.dates.first.strftime("%Y%m%d"),
            "SESSION_ID" => session.id.to_s,
            "ORGANISATION_CODE" => team.organisation.ods_code,
            "PERFORMING_PROFESSIONAL_EMAIL" => create(:user).email,
            "DOSE_SEQUENCE" => "1"
          )
        end

        let(:session) { create(:session, team:, location:, programmes:) }

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

      context "with a known school and community location type" do
        let(:data) do
          valid_data.merge(
            "SCHOOL_URN" => "123456",
            "SCHOOL_NAME" => "Waterloo Road",
            "Event Location Type" => "Hospital"
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

      context "when home educated and community location type and a named clinic" do
        let(:data) do
          valid_data.merge(
            "School Code" => "999999",
            "School" => "",
            "Event Location Type" => "Clinic",
            "Event Done At" => "A Clinic"
          )
        end

        it { should eq("A Clinic") }
      end

      context "when home educated and unknown care setting" do
        let(:data) do
          valid_data.merge("SCHOOL_URN" => "999999", "SCHOOL_NAME" => nil)
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

    describe "#notes" do
      subject { vaccination_record.notes }

      context "without notes" do
        let(:data) { valid_data }

        it { should be_nil }
      end

      context "with notes" do
        let(:data) { valid_data.merge("NOTES" => "Some notes.") }

        it { should eq("Some notes.") }
      end
    end

    describe "#outcome" do
      subject { vaccination_record.outcome }

      let(:data) { valid_data }

      let(:not_vaccinated_data) do
        valid_data.merge(
          "VACCINATED" => "N",
          "BATCH_EXPIRY_DATE" => "",
          "BATCH_NUMBER" => "",
          "ANATOMICAL_SITE" => ""
        )
      end

      it { should eq("administered") }

      context "with positive short vaccinated value" do
        let(:data) { valid_data.merge("VACCINATED" => "Y") }

        it { should eq("administered") }
      end

      context "with positive long vaccinated value" do
        let(:data) { valid_data.merge("VACCINATED" => "Yes") }

        it { should eq("administered") }
      end

      {
        "refused" => "refused",
        "unwell" => "unwell",
        "vaccination contraindicated" => "contraindicated",
        "already had elsewhere" => "already_had"
      }.each do |input_reason, expected_enum|
        context "with reason '#{input_reason}'" do
          let(:data) do
            not_vaccinated_data.merge("REASON_NOT_VACCINATED" => input_reason)
          end

          it { should eq(expected_enum) }
        end
      end
    end

    describe "#patient" do
      subject(:patient) { vaccination_record.patient }

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

      context "with an existing matching patient but mismatching capitalisation, without NHS number" do
        let(:data) do
          valid_data.except("NHS_NUMBER").merge(
            "PERSON_FORENAME" => "RON",
            "PERSON_SURNAME" => "WEASLEY",
            "PERSON_POSTCODE" => "sw1a 1aa"
          )
        end

        let!(:existing_patient) do
          create(
            :patient,
            given_name: "Ron",
            family_name: "Weasley",
            date_of_birth: Date.parse(date_of_birth),
            address_postcode:,
            nhs_number: "9990000018"
          )
        end

        it "still matches to a patient" do
          expect(patient).to eq(existing_patient)
        end
      end

      describe "#address_postcode" do
        subject { patient.address_postcode }

        context "with a valid postcode" do
          let(:data) { valid_data.merge("PERSON_POSTCODE" => "SW1 1AA") }

          it { should eq("SW1 1AA") }
        end

        context "with a valid unformatted postcode" do
          let(:data) { valid_data.merge("PERSON_POSTCODE" => "sw11aa") }

          it { should eq("SW1 1AA") }
        end
      end

      describe "#date_of_birth" do
        subject { patient.date_of_birth }

        context "with a YYYYMMDD value" do
          let(:data) { valid_data.merge("PERSON_DOB" => "20230901") }

          it { should eq(Date.new(2023, 9, 1)) }
        end

        context "with an Excel-exported-to-CSV date format" do
          let(:data) { valid_data.merge("PERSON_DOB" => "01/09/2023") }

          it { should eq(Date.new(2023, 9, 1)) }
        end
      end

      describe "#gender_code" do
        subject { patient.gender_code }

        let(:valid_data_without_gender) do
          valid_data.except("PERSON_GENDER_CODE")
        end

        shared_examples "with a value" do |key|
          context "with a 'unknown' value" do
            let(:data) { valid_data_without_gender.merge(key => "Unknown") }

            it { should eq("not_known") }
          end

          context "with a 'indeterminate' value" do
            let(:data) do
              valid_data_without_gender.merge(key => "Indeterminate")
            end

            it { should eq("not_known") }
          end

          context "with a 'not known' value" do
            let(:data) { valid_data_without_gender.merge(key => "Not Known") }

            it { should eq("not_known") }
          end

          context "with a 'male' value" do
            let(:data) { valid_data_without_gender.merge(key => "Male") }

            it { should eq("male") }
          end

          context "with a 'female' value" do
            let(:data) { valid_data_without_gender.merge(key => "Female") }

            it { should eq("female") }
          end

          context "with a 'not specified' value" do
            let(:data) do
              valid_data_without_gender.merge(key => "Not Specified")
            end

            it { should eq("not_specified") }
          end
        end

        include_examples "with a value", "PERSON_GENDER_CODE"
        include_examples "with a value", "PERSON_GENDER"
        include_examples "with a value", "Sex"
      end
    end

    describe "#performed_at" do
      subject { vaccination_record.performed_at }

      let(:year) { 2024 }
      let(:month) { 1 }
      let(:day) { 1 }

      context "with a HH:MM:SS value" do
        let(:data) { valid_data.merge("TIME_OF_VACCINATION" => "10:15:30") }

        it { should eq(Time.zone.local(year, month, day, 10, 15, 30)) }
      end

      context "with a HHMMSS value" do
        let(:data) { valid_data.merge("TIME_OF_VACCINATION" => "101530") }

        it { should eq(Time.zone.local(year, month, day, 10, 15, 30)) }
      end

      context "with a HH:MM value" do
        let(:data) { valid_data.merge("TIME_OF_VACCINATION" => "10:15") }

        it { should eq(Time.zone.local(year, month, day, 10, 15, 0)) }
      end

      context "with a HHMM value" do
        let(:data) { valid_data.merge("TIME_OF_VACCINATION" => "1015") }

        it { should eq(Time.zone.local(year, month, day, 10, 15, 0)) }
      end

      context "with a HH value" do
        let(:data) { valid_data.merge("TIME_OF_VACCINATION" => "10") }

        it { should eq(Time.zone.local(year, month, day, 10, 0, 0)) }
      end
    end

    describe "#performed_by_user" do
      subject { vaccination_record.performed_by_user }

      context "with a value" do
        let(:data) do
          valid_data.merge(
            "PERFORMING_PROFESSIONAL_EMAIL" => "nurse@example.com"
          )
        end

        context "and a user that doesn't exist" do
          it { expect(immunisation_import_row).to be_invalid }
        end

        context "and a user that does exist" do
          let!(:user) { create(:user, email: "nurse@example.com") }

          it { should eq(user) }
        end
      end
    end

    describe "#supplied_by" do
      subject { vaccination_record.supplied_by }

      context "with a value" do
        let(:data) { valid_data.merge("SUPPLIER_EMAIL" => "nurse@example.com") }

        context "and a user that doesn't exist" do
          it { expect(immunisation_import_row).to be_invalid }
        end

        context "and a user that does exist" do
          let!(:user) { create(:nurse, email: "nurse@example.com") }

          it { should eq(user) }
        end
      end
    end

    describe "#performed_ods_code" do
      subject { vaccination_record.performed_ods_code }

      context "with a value" do
        let(:data) { valid_data.merge("ORGANISATION_CODE" => "ABC") }

        it { should eq("ABC") }
      end
    end

    describe "#protocol" do
      subject { vaccination_record.protocol }

      it { should eq("pgd") }

      context "with a supplier" do
        before { create(:nurse, email: "nurse@example.com") }

        let(:data) { valid_data.merge("SUPPLIER_EMAIL" => "nurse@example.com") }

        it { should eq("national") }

        context "and nasal flu PSD" do
          let(:programmes) { [Programme.flu] }
          let(:data) do
            valid_flu_data.merge("SUPPLIER_EMAIL" => "nurse@example.com")
          end

          let!(:patient) { create(:patient, nhs_number:) }

          before do
            create(
              :patient_specific_direction,
              patient:,
              programme: programmes.first
            )
          end

          it { should eq("psd") }
        end

        context "and nasal flu PGD" do
          let(:programmes) { [Programme.flu] }
          let(:data) do
            valid_flu_data.merge("SUPPLIER_EMAIL" => "nurse@example.com")
          end

          it { should eq("pgd") }
        end
      end
    end

    context "without an expiry date" do
      let(:data) { valid_data.merge("BATCH_EXPIRY_DATE" => "") }

      it { should_not be_nil }
    end
  end

  describe "#batch_expiry" do
    subject { immunisation_import_row.batch_expiry&.to_date }

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

  describe "#batch_name" do
    subject { immunisation_import_row.batch_name&.to_s }

    context "with a BATCH_NUMBER field" do
      let(:data) { { "BATCH_NUMBER" => "abc" } }

      it { should eq("abc") }
    end

    context "with a Vaccination Batch Number field" do
      let(:data) { { "Vaccination Batch Number" => "abc" } }

      it { should eq("abc") }
    end
  end

  describe "#clinic_name" do
    subject { immunisation_import_row.clinic_name&.to_s }

    context "with a CLINIC_NAME field" do
      let(:data) { { "CLINIC_NAME" => "Hospital" } }

      it { should eq("Hospital") }
    end

    context "with an Event Done At field" do
      let(:data) { { "Event Done At" => "Hospital" } }

      it { should eq("Hospital") }
    end
  end

  describe "#date_of_vaccination" do
    subject { immunisation_import_row.date_of_vaccination&.to_s }

    context "with a DATE_OF_VACCINATION field" do
      let(:data) { { "DATE_OF_VACCINATION" => "01/01/2020" } }

      it { should eq("01/01/2020") }
    end

    context "with an Event Date field" do
      let(:data) { { "Event Date" => "01/01/2020" } }

      it { should eq("01/01/2020") }
    end
  end

  describe "#patient_date_of_birth" do
    subject { immunisation_import_row.patient_date_of_birth&.to_s }

    context "with a PERSON_DOB field" do
      let(:data) { { "PERSON_DOB" => "01/01/2020" } }

      it { should eq("01/01/2020") }
    end

    context "with a Date of Birth field" do
      let(:data) { { "Date of Birth" => "01/01/2020" } }

      it { should eq("01/01/2020") }
    end
  end

  describe "#patient_first_name" do
    subject { immunisation_import_row.patient_first_name&.to_s }

    context "with a PERSON_FORENAME field" do
      let(:data) { { "PERSON_FORENAME" => "Sally" } }

      it { should eq("Sally") }
    end

    context "with a First name field" do
      let(:data) { { "First name" => "Sally" } }

      it { should eq("Sally") }
    end
  end

  describe "#patient_gender_code" do
    subject { immunisation_import_row.patient_gender_code&.to_s }

    context "with a PERSON_GENDER_CODE field" do
      let(:data) { { "PERSON_GENDER_CODE" => "male" } }

      it { should eq("male") }
    end

    context "with a PERSON_GENDER field" do
      let(:data) { { "PERSON_GENDER" => "female" } }

      it { should eq("female") }
    end

    context "with a Sex field" do
      let(:data) { { "Sex" => "unknown" } }

      it { should eq("unknown") }
    end
  end

  describe "#patient_last_name" do
    subject { immunisation_import_row.patient_last_name&.to_s }

    context "with a PERSON_SURNAME field" do
      let(:data) { { "PERSON_SURNAME" => "Phillips" } }

      it { should eq("Phillips") }
    end

    context "with a Surname field" do
      let(:data) { { "Surname" => "Phillips" } }

      it { should eq("Phillips") }
    end
  end

  describe "#performed_by_given_name" do
    subject { immunisation_import_row.performed_by_given_name&.to_s }

    let(:data) { { "PERFORMING_PROFESSIONAL_FORENAME" => "John" } }

    it { should eq("John") }
  end

  describe "#performed_by_family_name" do
    subject { immunisation_import_row.performed_by_family_name&.to_s }

    let(:data) { { "PERFORMING_PROFESSIONAL_SURNAME" => "Smith" } }

    it { should eq("Smith") }
  end

  describe "#school_name" do
    subject { immunisation_import_row.school_name&.to_s }

    context "with a SCHOOL_NAME field" do
      let(:data) { { "SCHOOL_NAME" => "Waterloo Road" } }

      it { should eq("Waterloo Road") }
    end

    context "with a School field" do
      let(:data) { { "School" => "Waterloo Road" } }

      it { should eq("Waterloo Road") }
    end
  end

  describe "#school_urn" do
    subject { immunisation_import_row.school_urn&.to_s }

    context "with a SCHOOL_URN field" do
      let(:data) { { "SCHOOL_URN" => "123456" } }

      it { should eq("123456") }
    end

    context "with a School Code field" do
      let(:data) { { "School Code" => "123456" } }

      it { should eq("123456") }
    end
  end
end
