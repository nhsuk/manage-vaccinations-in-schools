# frozen_string_literal: true

describe ImmunisationImport::RowParser do
  subject(:row_parser) { described_class.new(data) }

  describe "#administered" do
    subject { row_parser.administered }

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

  describe "#batch_expiry" do
    subject { row_parser.batch_expiry }

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
    subject { row_parser.batch_name }

    context "without a value" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with a value" do
      let(:data) { { "BATCH_NUMBER" => "abc" } }

      it { should eq("abc") }
    end
  end

  describe "#care_setting" do
    subject { row_parser.care_setting }

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

  describe "#delivery_method" do
    subject { row_parser.delivery_method }

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
    subject { row_parser.delivery_site }

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

  describe "#notes" do
    subject { row_parser.notes }

    context "without notes" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with blank notes" do
      let(:data) { { "NOTES" => "" } }

      it { should be_nil }
    end

    context "with notes" do
      let(:data) { { "NOTES" => "Some notes." } }

      it { should eq("Some notes.") }
    end
  end

  describe "#patient_date_of_birth" do
    subject { row_parser.patient_date_of_birth }

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
    subject { row_parser.patient_gender_code }

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
    subject { row_parser.patient_postcode }

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

  describe "#performed_by_given_name" do
    subject { row_parser.performed_by_given_name }

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
    subject { row_parser.performed_by_family_name }

    context "without a value" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with a value" do
      let(:data) { { "PERFORMING_PROFESSIONAL_SURNAME" => "Smith" } }

      it { should eq("Smith") }
    end
  end

  describe "#performed_ods_code" do
    subject { row_parser.performed_ods_code }

    context "without a value" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with a value" do
      let(:data) { { "ORGANISATION_CODE" => "abc" } }

      it { should eq("ABC") }
    end
  end

  describe "#reason_not_vaccinated" do
    subject { row_parser.reason_not_vaccinated }

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

  describe "#time_of_vaccination" do
    subject { row_parser.time_of_vaccination }

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
end
