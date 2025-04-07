# frozen_string_literal: true

describe Reports::CSVSchoolMoves do
  subject(:csv) { described_class.call([school_move]) }

  let(:patient) { create(:patient, school: old_school) }
  let(:old_school) { create(:school, :secondary) }
  let(:new_school) { create(:school, :secondary) }
  let(:school_move) do
    create(:school_move_log_entry, patient:, school: new_school)
  end

  describe ".call" do
    let(:rows) { CSV.parse(csv, headers: true) }

    it "returns a CSV with the school moves data" do
      expect(rows.first.to_hash).to include(
        {
          "NHS_REF" => patient.nhs_number,
          "SURNAME" => patient.family_name,
          "FORENAME" => patient.given_name,
          "GENDER" => patient.gender_code.humanize,
          "DOB" => patient.date_of_birth.to_fs(:govuk),
          "ADDRESS1" => patient.address_line_1,
          "ADDRESS2" => patient.address_line_2,
          "ADDRESS3" => nil,
          "TOWN" => patient.address_town,
          "POSTCODE" => patient.address_postcode,
          "COUNTY" => nil,
          "ETHNIC_OR" => nil,
          "ETHNIC_DESCRIPTION" => nil,
          "NATIONAL_URN_NO" => new_school.urn,
          "BASE_NAME" => new_school.name,
          "STARTDATE" => new_school.created_at.to_fs(:govuk),
          "STUD_ID" => nil,
          "DES_NUMBER" => nil
        }
      )
    end

    context "when moving to home education" do
      let(:patient) { create(:patient, :home_educated) }
      let(:school_move) do
        create(:school_move_log_entry, :home_educated, patient:)
      end

      it "returns '999999' as the URN" do
        expect(rows.first["NATIONAL_URN_NO"]).to eq("999999")
      end
    end

    context "when moving to an unknown school" do
      let(:patient) { create(:patient, school: nil) }
      let(:school_move) do
        create(:school_move_log_entry, :unknown_school, patient:)
      end

      it "returns '888888' as the URN" do
        expect(rows.first["NATIONAL_URN_NO"]).to eq("888888")
      end
    end
  end
end
