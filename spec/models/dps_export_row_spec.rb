# frozen_string_literal: true

require "rails_helper"
require "csv"

describe DPSExportRow do
  subject(:row) { described_class.new(vaccination_record) }

  let(:vaccine) { create :vaccine, :gardasil_9, dose: 0.5 }
  let(:patient) { create :patient, date_of_birth: "2012-12-29" }
  let(:vaccination_record) do
    create(
      :vaccination_record,
      vaccine:,
      batch: create(:batch, vaccine:, name: "AB1234", expiry: "2025-07-01"),
      delivery_site: :left_arm_upper_position,
      delivery_method: :intramuscular,
      recorded_at: Time.zone.local(2024, 7, 23, 19, 31, 47),
      created_at: Time.zone.local(2024, 6, 12, 11, 28, 31),
      user: create(:user, full_name: "Jane Doe"),
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

    it "has site_code" do
      expect(array[7]).to eq vaccination_record.campaign.team.ods_code
    end

    it "has site_code_type_uri" do
      expect(array[8]).to eq "https://fhir.nhs.uk/Id/ods-organization-code"
    end

    it "has action_flag" do
      expect(array[11]).to eq "new"
    end

    it "has performing_professional_forename" do
      expect(array[12]).to eq "Jane"
    end

    it "has performing_professional_surname" do
      expect(array[13]).to eq "Doe"
    end

    it "has recorded_date" do
      expect(array[14]).to eq "20240612"
    end

    it "has primary_source" do
      expect(array[15]).to eq "FALSE"
    end

    it "has batch_number" do
      expect(array[22]).to eq "AB1234"
    end

    it "has expiry_date" do
      expect(array[23]).to eq "20250701"
    end

    it "has site_of_vaccination_code" do
      expect(array[24]).to eq "368208006"
    end

    it "has site_of_vaccination_term" do
      expect(array[25]).to eq "Structure of left upper arm (body structure)"
    end

    context "when the vaccine is a nasal spray" do
      let(:vaccine) { create :vaccine, :fluenz_tetra }

      let(:vaccination_record) do
        create(
          :vaccination_record,
          vaccine:,
          batch: create(:batch, vaccine:),
          delivery_site: :nose,
          delivery_method: :nasal_spray
        )
      end

      it "has route_of_vaccination_code" do
        expect(array[26]).to eq "46713006"
      end

      it "has route_of_vaccination_term" do
        expect(array[27]).to eq "Nasal route (qualifier value)"
      end
    end

    context "when the vaccine is an intramuscular injection" do
      let(:vaccine) { create :vaccine, :fluarix_tetra }

      it "has route_of_vaccination_code" do
        expect(array[26]).to eq "78421000"
      end

      it "has route_of_vaccination_term" do
        expect(array[27]).to eq "Intramuscular route (qualifier value)"
      end
    end

    it "has dose_amount" do
      expect(array[28]).to eq 0.5
    end

    it "has dose_unit_code" do
      expect(array[29]).to eq "258773002"
    end

    it "has dose_unit_term" do
      expect(array[30]).to eq "Milliliter (qualifier value)"
    end

    it "has indication_code" do
      expect(array[31]).to be_nil
    end
  end
end
