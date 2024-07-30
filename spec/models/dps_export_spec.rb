# frozen_string_literal: true

require "rails_helper"
require "csv"

describe DPSExport do
  let(:vaccination_records) do
    create_list(
      :vaccination_record,
      3,
      patient_session: create(:patient_session)
    )
    VaccinationRecord.all
  end

  describe "#to_csv" do
    subject(:csv) { described_class.new(vaccination_records).to_csv }

    describe "header" do
      subject(:header) { csv.split("\n").first }

      it "has all the fields in the correct order" do
        expect(csv.split("\n").first.split(",")).to eq %w[
             "NHS_NUMBER"
             "PERSON_FORENAME"
             "PERSON_SURNAME"
             "PERSON_DOB"
             "PERSON_GENDER_CODE"
             "PERSON_POSTCODE"
             "DATE_AND_TIME"
             "SITE_CODE"
             "SITE_CODE_TYPE_URI"
             "UNIQUE_ID"
             "UNIQUE_ID_URI"
             "ACTION_FLAG"
             "PERFORMING_PROFESSIONAL_FORENAME"
             "PERFORMING_PROFESSIONAL_SURNAME"
             "RECORDED_DATE"
             "PRIMARY_SOURCE"
             "VACCINATION_PROCEDURE_CODE"
             "VACCINATION_PROCEDURE_TERM"
             "DOSE_SEQUENCE"
             "VACCINE_PRODUCT_CODE"
             "VACCINE_PRODUCT_TERM"
             "VACCINE_MANUFACTURER"
             "BATCH_NUMBER"
             "EXPIRY_DATE"
             "SITE_OF_VACCINATION_CODE"
             "SITE_OF_VACCINATION_TERM"
             "ROUTE_OF_VACCINATION_CODE"
             "ROUTE_OF_VACCINATION_TERM"
             "DOSE_AMOUNT"
             "DOSE_UNIT_CODE"
             "DOSE_UNIT_TERM"
             "INDICATION_CODE"
             "LOCATION_CODE"
             "LOCATION_CODE_TYPE_URI"
           ]
      end
    end
  end

  describe "#export_csv" do
    subject(:export) { described_class.new(vaccination_records).export_csv }

    it "returns the CSV export" do
      expect(export).to eq described_class.new(vaccination_records).to_csv
    end

    it "updates the exported_to_dps_at timestamp" do
      Timecop.freeze do
        expect { export }.to change {
          vaccination_records.first.reload.exported_to_dps_at&.change(nsec: 0)
        }.from(nil).to(Time.zone.now.change(nsec: 0))
      end
    end
  end
end
