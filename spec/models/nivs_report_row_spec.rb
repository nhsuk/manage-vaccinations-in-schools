# frozen_string_literal: true

require "rails_helper"

describe NivsReport::Row, type: :model do
  describe "#to_a" do
    subject(:values) { nivs_report_row.to_a }

    let(:patient_session) { create(:patient_session, :vaccinated) }
    let(:vaccination_record) { patient_session.vaccination_records.first }
    let(:nivs_report_row) { described_class.new(vaccination_record) }

    it "includes information about the team who administered the vaccinatino" do
      vaccination_record.campaign.team.update!(ods_code: "X26")
      expect(values[0]).to eq "X26"
    end

    it "includes information about the school where the vaccination was administered" do
      vaccination_record.session.location.update!(
        urn: "123456",
        name: "Test School"
      )

      expect(values[1..2]).to eq ["123456", "Test School"]
    end

    it "includes information about the patient" do
      vaccination_record.patient.update!(
        nhs_number: "1234567890",
        first_name: "Test",
        last_name: "Patient",
        date_of_birth: Date.new(2010, 1, 1),
        address_postcode: "AB1 2CD"
      )

      expect(values[3..8]).to eq [
           "1234567890",
           "Test",
           "Patient",
           "20100101",
           "Not Known",
           "AB1 2CD"
         ]
    end

    it "includes information about the vaccination" do
      vaccination_record.update!(
        recorded_at: Time.zone.local(2020, 1, 1, 12, 0, 0),
        delivery_site: "left_arm_upper_position"
      )
      vaccination_record.batch.update!(vaccine: create(:vaccine, :hpv))
      vaccination_record.batch.update!(
        name: "AB1234",
        expiry: Date.new(2021, 1, 1)
      )

      expect(values[9..17]).to eq [
           "20200101",
           "Gardasil 9",
           "AB1234",
           "20210101",
           "Left Upper Arm",
           "1",
           "MAVIS-#{vaccination_record.patient.id}",
           "",
           "1 - School"
         ]
    end

    context "for nasal flu" do
      it "includes the correct delivery site" do
        vaccination_record.batch.update!(
          vaccine: create(:vaccine, :flu, :fluenz_tetra)
        )
        expect(values[13]).to eq "Nasal"
      end
    end

    context "for lower arm" do
      it "sets the delivery site to the appropriate arm, at least" do
        vaccination_record.update!(delivery_site: "left_arm_lower_position")
        expect(values[13]).to eq "Left Upper Arm"
      end
    end
  end
end
