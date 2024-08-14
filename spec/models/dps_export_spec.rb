# frozen_string_literal: true

# == Schema Information
#
# Table name: dps_exports
#
#  id          :bigint           not null, primary key
#  filename    :string           not null
#  sent_at     :datetime
#  status      :string           default("pending"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  campaign_id :bigint           not null
#  message_id  :string
#
# Indexes
#
#  index_dps_exports_on_campaign_id  (campaign_id)
#
# Foreign Keys
#
#  fk_rails_...  (campaign_id => campaigns.id)
#
require "rails_helper"
require "csv"

describe DPSExport, type: :model do
  subject(:dps_export) do
    described_class.create!(campaign:, filename: "test.csv")
  end

  let(:campaign) { patient_session.campaign }
  let(:patient_session) { create(:patient_session) }

  before { create_list(:vaccination_record, 2, patient_session:) }

  describe "#csv" do
    subject(:csv) { dps_export.csv }

    describe "header" do
      subject(:header) { csv.split("\n").first }

      it "has all the fields in the correct order" do
        expect(header.split(",")).to eq %w[
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

    describe "body" do
      subject(:rows) { csv.split("\n").drop(1) }

      it "contains the existing vaccination records" do
        expect(rows.count).to eq(2)
      end
    end
  end
end
