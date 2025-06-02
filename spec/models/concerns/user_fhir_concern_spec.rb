# frozen_string_literal: true

describe UserFHIRConcern do
  include FHIRHelper

  let(:user) { create(:user) }

  describe "#to_fhir_practitioner" do
    subject(:practitioner_record) { user.to_fhir_practitioner }

    it "adds the family name" do
      expect(practitioner_record.name.first.family).to eq user.family_name
    end

    it "adds the given name" do
      expect(practitioner_record.name.first.given.first).to eq user.given_name
    end

    it "sets the id" do
      expect(practitioner_record.id).to eq "User/#{user.id}"
    end
  end

  describe "#fhir_id" do
    it "returns the correct FHIR ID" do
      expect(user.fhir_id).to eq "User/#{user.id}"
    end
  end
end
