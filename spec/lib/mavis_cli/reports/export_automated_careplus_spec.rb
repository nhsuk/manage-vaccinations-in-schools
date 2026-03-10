# frozen_string_literal: true

describe MavisCLI::Reports::ExportAutomatedCareplus do
  describe "#call" do
    subject(:command) do
      capture_output do
        described_class.new.call(
          ods_code: organisation.ods_code,
          start_date: "2025-09-01",
          end_date: "2026-03-10",
          output: output_path
        )
      end
    end

    let(:organisation) { create(:organisation) }
    let(:team) { create(:team, organisation:, programmes: Programme.all) }
    let(:output_path) { Rails.root.join("tmp/test_automated_export.csv").to_s }

    before do
      team
      allow(Reports::AutomatedCareplusExporter).to receive(:call).and_return(
        "csv content"
      )
    end

    it "calls the automated careplus exporter" do
      command

      expect(Reports::AutomatedCareplusExporter).to have_received(:call).with(
        team:,
        academic_year: AcademicYear.current,
        start_date: Date.new(2025, 9, 1),
        end_date: Date.new(2026, 3, 10)
      )
    end

    context "when the organisation does not exist" do
      it "warns and returns without calling the exporter" do
        capture_output do
          described_class.new.call(ods_code: "UNKNOWN", output: output_path)
        end

        expect(Reports::AutomatedCareplusExporter).not_to have_received(:call)
      end
    end

    context "when the organisation has multiple teams and no workgroup is given" do
      before { create(:team, organisation:, programmes: Programme.all) }

      it "warns and returns without calling the exporter" do
        command

        expect(Reports::AutomatedCareplusExporter).not_to have_received(:call)
      end
    end

    context "when a workgroup is specified" do
      it "calls the exporter with the matching team" do
        capture_output do
          described_class.new.call(
            ods_code: organisation.ods_code,
            workgroup: team.workgroup,
            output: output_path
          )
        end

        expect(Reports::AutomatedCareplusExporter).to have_received(:call).with(
          hash_including(team:)
        )
      end
    end

    context "when a custom academic year is specified" do
      it "passes the academic year to the exporter" do
        capture_output do
          described_class.new.call(
            ods_code: organisation.ods_code,
            academic_year: 2024,
            output: output_path
          )
        end

        expect(Reports::AutomatedCareplusExporter).to have_received(:call).with(
          hash_including(academic_year: 2024)
        )
      end
    end
  end
end
