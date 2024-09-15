# frozen_string_literal: true

describe CohortImportRow, type: :model do
  subject(:cohort_import_row) { described_class.new(data:) }

  let(:valid_data) do
    {
      "SCHOOL_URN" => "123456",
      "SCHOOL_NAME" => "Surrey Primary",
      "PARENT_NAME" => "John Smith",
      "PARENT_RELATIONSHIP" => "Father",
      "PARENT_EMAIL" => "john@example.com",
      "PARENT_PHONE" => "07412345678",
      "CHILD_FIRST_NAME" => "Jimmy",
      "CHILD_LAST_NAME" => "Smith",
      "CHILD_COMMON_NAME" => "Jim",
      "CHILD_DATE_OF_BIRTH" => "2010-01-01",
      "CHILD_ADDRESS_LINE_1" => "10 Downing Street",
      "CHILD_ADDRESS_LINE_2" => "",
      "CHILD_ADDRESS_TOWN" => "London",
      "CHILD_ADDRESS_POSTCODE" => "SW1A 1AA",
      "CHILD_NHS_NUMBER" => "1234567890"
    }
  end

  before { create(:location, :school, urn: "123456") }

  describe "#to_parent" do
    subject(:parent) { cohort_import_row.to_parent }

    let(:data) { valid_data }

    it do
      expect(parent).to have_attributes(
        name: "John Smith",
        email: "john@example.com",
        phone: "07412345678",
        phone_receive_updates: false
      )
    end

    context "with an existing parent" do
      let!(:existing_parent) do
        create(:parent, name: "John Smith", email: "john@example.com")
      end

      it { should eq(existing_parent) }

      it "doesn't change phone_receive_updates" do
        expect(parent.phone_receive_updates).to eq(
          existing_parent.phone_receive_updates
        )
      end
    end
  end

  describe "#to_patient" do
    subject(:patient) { cohort_import_row.to_patient }

    let(:data) { valid_data }

    it { should_not be_nil }
  end
end
