# frozen_string_literal: true

describe SchoolMoveExport do
  subject(:school_move_export) do
    described_class.new(request_session:, current_user:)
  end

  let(:request_session) { {} }
  let(:current_user) { team.users.first }
  let(:team) { create(:team, :with_one_nurse) }

  describe "#wizard_steps" do
    subject { school_move_export.wizard_steps }

    it { should eq(%i[dates confirm]) }
  end

  describe "dates formatted" do
    let(:date) { Date.new(2023, 1, 1) }

    describe "#date_from_formatted" do
      context "when date_from is present" do
        before do
          school_move_export.assign_attributes(
            {
              "date_from(3i)" => date.day.to_s,
              "date_from(2i)" => date.month.to_s,
              "date_from(1i)" => date.year.to_s,
              "wizard_step" => :dates
            }
          )
        end

        it "returns the formatted date" do
          expect(school_move_export.date_from_formatted).to eq(
            "01 January 2023"
          )
        end
      end

      context "when date_from is not present" do
        it do
          expect(school_move_export.date_from_formatted).to eq(
            "Earliest recorded vaccination"
          )
        end
      end
    end

    describe "#date_to_formatted" do
      context "when date_to is present" do
        before do
          school_move_export.assign_attributes(
            {
              "date_from(3i)" => date.day.to_s,
              "date_from(2i)" => date.month.to_s,
              "date_from(1i)" => date.year.to_s,
              "wizard_step" => :dates
            }
          )
        end

        it "returns the formatted date" do
          expect(school_move_export.date_from_formatted).to eq(
            "01 January 2023"
          )
        end
      end

      context "when date_to is not present" do
        it do
          expect(school_move_export.date_to_formatted).to eq(
            "Latest recorded vaccination"
          )
        end
      end
    end
  end

  describe "#csv_filename" do
    before do
      school_move_export.assign_attributes(
        {
          "date_from(3i)" => "01",
          "date_from(2i)" => "01",
          "date_from(1i)" => "2024",
          "date_to(3i)" => "31",
          "date_to(2i)" => "12",
          "date_to(1i)" => "2025",
          "wizard_step" => :dates
        }
      )
    end

    it "returns the correct filename" do
      expected_filename = "school_moves_export_2024-01-01_to_2025-12-31.csv"
      expect(school_move_export.csv_filename).to eq(expected_filename)
    end
  end
end
