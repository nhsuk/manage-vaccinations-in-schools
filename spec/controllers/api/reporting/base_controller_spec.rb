# frozen_string_literal: true

describe API::Reporting::BaseController do
  let(:mock_headers) { {} }
  let(:mock_response) do
    instance_double(ActionDispatch::Response, headers: mock_headers)
  end

  describe "#set_json_headers" do
    before { allow(controller).to receive(:response).and_return(mock_response) }

    it "sets the Last-Modified header to now" do
      controller.send(:set_json_headers)
      last_modified = controller.send(:response).headers["Last-Modified"]
      expect(Time.zone.parse(last_modified)).to be_within(1.second).of(
        Time.zone.now
      )
    end
  end

  describe "#set_csv_headers" do
    let(:filename) { "my-test.csv" }

    before { allow(controller).to receive(:response).and_return(mock_response) }

    it "sets the Content-Type header to text/csv" do
      controller.send(:set_csv_headers, filename:)
      expect(controller.send(:response).headers["Content-Type"]).to eq(
        "text/csv"
      )
    end

    it "sets the Last-Modified header to now" do
      controller.send(:set_csv_headers, filename:)
      last_modified = controller.send(:response).headers["Last-Modified"]
      expect(Time.zone.parse(last_modified)).to be_within(1.second).of(
        Time.zone.now
      )
    end

    it "sets the Content-Disposition header to be an attachment, with the given filename" do
      controller.send(:set_csv_headers, filename:)
      expect(controller.send(:response).headers["Content-Disposition"]).to eq(
        "attachment; filename=#{filename}"
      )
    end

    it "sets the Cache-Control header to no-cache" do
      controller.send(:set_csv_headers, filename:)
      expect(controller.send(:response).headers["Cache-Control"]).to eq(
        "no-cache"
      )
    end
  end

  describe "#csv_filename" do
    it "ends in .csv" do
      expect(controller.send(:csv_filename)).to end_with(".csv")
    end

    context "given a prefix" do
      it "starts with the given prefix" do
        expect(
          controller.send(:csv_filename, prefix: "myprefix")
        ).to start_with("myprefix")
      end
    end

    context "given no prefix" do
      it "starts with data" do
        expect(controller.send(:csv_filename, prefix: "data")).to start_with(
          "data"
        )
      end
    end

    it "includes the @filters" do
      controller.send(
        :instance_variable_set,
        "@filters",
        "string-representation-of-filters-instance-variable"
      )
      expect(controller.send(:csv_filename)).to include(
        "string-representation-of-filters-instance-variable"
      )
    end

    it "includes the given timestamp in iso8601, with any non-alphanumeric characters removed" do
      timestamp = Time.zone.parse("2025-07-01T12:13:14 +01:00")
      expect(controller.send(:csv_filename, timestamp:)).to include(
        "20250701T1213140100"
      )
    end
  end

  describe "#to_csv" do
    context "given some records" do
      let!(:programme) { create(:programme, type: "hpv") }
      let(:patient) { create(:patient, random_nhs_number: true) }
      let(:records) { VaccinationRecord.where("id > 0") }
      let(:result) { controller.send(:to_csv, records:, header_mappings:) }

      before do
        create_list(
          :vaccination_record,
          2,
          patient:,
          programme:,
          outcome: "administered"
        )
      end

      context "and some header mappings" do
        let(:header_mappings) do
          {
            "Patient ID" => :patient_id,
            "Outcome" => :outcome,
            "UUID" => :uuid
          }
        end

        describe "the returned CSV" do
          let(:returned_csv_rows) { result.split("\n") }

          it "has a header row matching the given header mapping names" do
            expect(returned_csv_rows.first).to eq(
              header_mappings.keys.join(",")
            )
          end

          it "has a row for each record" do
            expect(returned_csv_rows.size).to eq(3)
          end

          describe "the row for each record" do
            it "has each attribute named in the header mappings in the right order" do
              expect(returned_csv_rows[1]).to eq(
                "#{records[0].patient_id},administered,#{records[0].uuid}"
              )
              expect(returned_csv_rows[2]).to eq(
                "#{records[1].patient_id},administered,#{records[1].uuid}"
              )
            end

            context "if the record does not have one of the attributes in the header mappings" do
              let(:header_mappings) do
                {
                  "Patient ID" => :patient_id,
                  "Outcome" => :outcome,
                  "Non-existent attribute" => :non_existent_attribute
                }
              end

              it "does not raise an error" do
                expect { result }.not_to raise_error
              end

              it "has an empty value in the result for that attribute" do
                expect(returned_csv_rows[1]).to eq(
                  "#{records[0].patient_id},administered,"
                )
              end
            end
          end
        end
      end
    end
  end
end
