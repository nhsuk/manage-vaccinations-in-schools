# frozen_string_literal: true

require "rails_helper"
require "csv"

describe DPSExportRow do
  subject(:row) { described_class.new(vaccination_record) }

  let(:patient) { create :patient, date_of_birth: "2012-12-29" }
  let(:vaccination_record) do
    create(
      :vaccination_record,
      delivery_site: :left_arm_upper_position,
      recorded_at: Time.zone.local(2024, 7, 23, 19, 31, 47),
      created_at: Time.zone.local(2024, 6, 12, 11, 28, 31),
      patient_attributes: {
        date_of_birth: "2012-12-29"
      }
    )
  end

  describe "to_a" do
    subject(:array) { row.to_a }

    it "has the nhs_number" do
      expect(array[0]).to eq vaccination_record.patient.nhs_number
    end

    it "has person_firstname" do
      expect(array[1]).to eq vaccination_record.patient.first_name
    end

    it "has person_surname" do
      expect(array[2]).to eq vaccination_record.patient.last_name
    end

    it "has person_dob" do
      expect(array[3]).to eq "20121229"
    end

    it "has person_gender_code" do
      expect(
        array[4]
      ).to eq vaccination_record.patient.gender_code_before_type_cast
    end

    it "has person_postcode" do
      expect(array[5]).to eq vaccination_record.patient.address_postcode
    end

    it "has date_and_time" do
      expect(array[6]).to eq "20240723T19314700"
    end

    it "has recorded_date" do
      expect(array[7]).to eq "20240612"
    end

    it "has site_of_vaccination_code" do
      expect(array[8]).to eq "368208006"
    end

    it "has site_of_vaccination_term" do
      expect(array[9]).to eq "Structure of left upper arm (body structure)"
    end
  end
end
