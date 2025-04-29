# frozen_string_literal: true

describe Reports::SchoolMovesExporter do
  subject(:exporter) do
    described_class.new(organisation:, start_date:, end_date:)
  end

  let(:organisation) { create(:organisation) }
  let(:start_date) { nil }
  let(:end_date) { nil }

  describe "#row_count" do
    subject { exporter.row_count }

    let(:one_day_ago) { 1.day.ago }
    let(:three_days_ago) { 3.days.ago }

    before do
      3.times do
        patient = create(:patient, organisation:)
        create(:school_move_log_entry, patient:, created_at: one_day_ago)
      end

      2.times do
        patient = create(:patient, organisation:)
        create(:school_move_log_entry, patient:, created_at: three_days_ago)
      end
    end

    it { should eq(5) }

    context "when date range is specified" do
      let(:start_date) { one_day_ago }

      it { should eq(3) }
    end
  end

  describe "#csv_data" do
    subject(:csv_data) { exporter.csv_data }

    let(:rows) { CSV.parse(csv_data, headers: true) }

    context "with a standard school move" do
      let(:old_school) { create(:school, :secondary) }
      let(:new_school) { create(:school, :secondary) }

      before do
        patient = create(:patient, school: old_school, organisation:)
        create(:school_move_log_entry, patient:, school: new_school)
      end

      it "returns a CSV with the school moves data" do
        entry = SchoolMoveLogEntry.last

        expect(rows.first.to_hash).to include(
          {
            "NHS_REF" => entry.patient.nhs_number,
            "SURNAME" => entry.patient.family_name,
            "FORENAME" => entry.patient.given_name,
            "GENDER" => entry.patient.gender_code.humanize,
            "DOB" => entry.patient.date_of_birth.iso8601,
            "ADDRESS1" => entry.patient.address_line_1,
            "ADDRESS2" => entry.patient.address_line_2,
            "ADDRESS3" => nil,
            "TOWN" => entry.patient.address_town,
            "POSTCODE" => entry.patient.address_postcode,
            "COUNTY" => nil,
            "ETHNIC_OR" => nil,
            "ETHNIC_DESCRIPTION" => nil,
            "NATIONAL_URN_NO" => new_school.urn,
            "BASE_NAME" => new_school.name,
            "STARTDATE" => entry.created_at.iso8601,
            "STUD_ID" => nil,
            "DES_NUMBER" => nil
          }
        )
      end
    end

    context "when moving to home education" do
      before do
        patient = create(:patient, :home_educated, organisation:)
        create(:school_move_log_entry, :home_educated, patient:)
      end

      it "returns '999999' as the URN" do
        expect(rows.first["NATIONAL_URN_NO"]).to eq("999999")
      end
    end

    context "when moving to an unknown school" do
      before do
        patient = create(:patient, school: nil, organisation:)
        create(:school_move_log_entry, :unknown_school, patient:)
      end

      it "returns '888888' as the URN" do
        expect(rows.first["NATIONAL_URN_NO"]).to eq("888888")
      end
    end
  end
end
