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

    let(:school) { create(:school, :secondary, organisation:) }

    before do
      3.times do
        patient = create(:patient, school:, organisation:)
        create(
          :school_move_log_entry,
          patient:,
          school:,
          created_at: one_day_ago
        )
      end

      2.times do
        patient = create(:patient, school:, organisation:)
        create(
          :school_move_log_entry,
          patient:,
          school:,
          created_at: three_days_ago
        )
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
      let(:old_school) { create(:school, :secondary, organisation:) }
      let(:new_school) { create(:school, :secondary, organisation:) }

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

    context "when a patient moves out of an organisation" do
      let(:organisation1) { create(:organisation) }
      let(:organisation2) { create(:organisation) }

      let(:school1) { create(:school, :secondary, organisation: organisation1) }
      let(:school2) { create(:school, :secondary, organisation: organisation2) }

      let(:patient) { create(:patient, organisation: organisation2) }

      let(:created_at1) { 1.week.ago }
      let(:created_at2) { Time.current }

      before do
        # first they were added to school 1
        create(
          :school_move_log_entry,
          patient:,
          school: school1,
          created_at: created_at1
        )

        # next they were moved to school 2
        create(
          :school_move_log_entry,
          patient:,
          school: school2,
          created_at: created_at2
        )
      end

      context "from the old organisation" do
        let(:organisation) { organisation1 }

        it "includes two rows" do
          expect(rows.count).to eq(2)
        end

        it "has the move in and the move out" do
          expect(rows[0].to_hash).to include(
            {
              "NHS_REF" => patient.nhs_number,
              "NATIONAL_URN_NO" => school1.urn,
              "BASE_NAME" => school1.name,
              "STARTDATE" => created_at1.iso8601
            }
          )

          expect(rows[1].to_hash).to include(
            {
              "NHS_REF" => patient.nhs_number,
              "NATIONAL_URN_NO" => school2.urn,
              "BASE_NAME" => school2.name,
              "STARTDATE" => created_at2.iso8601
            }
          )
        end
      end

      context "from the new organisation" do
        let(:organisation) { organisation2 }

        it "includes one row" do
          expect(rows.count).to eq(1)
        end

        it "has the move in" do
          expect(rows.first.to_hash).to include(
            {
              "NHS_REF" => patient.nhs_number,
              "NATIONAL_URN_NO" => school2.urn,
              "BASE_NAME" => school2.name,
              "STARTDATE" => created_at2.iso8601
            }
          )
        end
      end
    end
  end
end
