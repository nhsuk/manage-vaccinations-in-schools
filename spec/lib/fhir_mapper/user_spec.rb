# frozen_string_literal: true

describe FHIRMapper::User do
  let(:user) { create(:user) }
  let(:mapper) { described_class.new(user) }

  describe "#fhir_practitioner" do
    subject(:practitioner_record) do
      mapper.fhir_practitioner(reference_id: "Practitioner42")
    end

    it "adds the family name" do
      expect(practitioner_record.name.first.family).to eq user.family_name
    end

    it "adds the given name" do
      expect(practitioner_record.name.first.given.first).to eq user.given_name
    end

    it "sets the id" do
      expect(practitioner_record.id).to eq "Practitioner42"
    end
  end
end
