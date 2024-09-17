# frozen_string_literal: true

# == Schema Information
#
# Table name: patients
#
#  id                       :bigint           not null, primary key
#  address_line_1           :string
#  address_line_2           :string
#  address_postcode         :string           not null
#  address_town             :string
#  common_name              :string
#  consent_reminder_sent_at :datetime
#  consent_request_sent_at  :datetime
#  date_of_birth            :date             not null
#  first_name               :string           not null
#  gender_code              :integer          default("not_known"), not null
#  home_educated            :boolean
#  last_name                :string           not null
#  nhs_number               :string
#  pending_changes          :jsonb            not null
#  recorded_at              :datetime
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  school_id                :bigint
#
# Indexes
#
#  index_patients_on_nhs_number  (nhs_number) UNIQUE
#  index_patients_on_school_id   (school_id)
#
# Foreign Keys
#
#  fk_rails_...  (school_id => locations.id)
#

describe Patient, type: :model do
  describe "validations" do
    context "when home educated" do
      subject(:patient) { build(:patient, :home_educated) }

      it { should validate_absence_of(:school) }
    end

    context "with an invalid school" do
      subject(:patient) do
        build(:patient, school: create(:location, :generic_clinic))
      end

      it "is invalid" do
        expect(patient.valid?).to be(false)
        expect(patient.errors[:school]).to include(
          "must be a school location type"
        )
      end
    end
  end

  describe "scopes" do
    describe "#active" do
      subject(:active) { described_class.active }

      context "with a patient belonging to no sessions" do
        before { create(:patient) }

        it { should be_empty }
      end

      context "with a patient belonging to a draft session" do
        before { create(:patient_session, :draft) }

        it { should be_empty }
      end

      context "with a patient belonging to an active session" do
        let!(:patient) { create(:patient_session, :active).patient }

        it { should include(patient) }
      end
    end
  end

  describe "#find_existing" do
    subject(:find_existing) do
      described_class.find_existing(
        nhs_number:,
        first_name:,
        last_name:,
        date_of_birth:,
        address_postcode:
      )
    end

    let(:nhs_number) { "0123456789" }
    let(:first_name) { "John" }
    let(:last_name) { "Smith" }
    let(:date_of_birth) { Date.new(1999, 1, 1) }
    let(:address_postcode) { "SW1A 1AA" }

    context "with no matches" do
      let(:patient) { create(:patient) }

      it { should_not include(patient) }
    end

    context "with a matching NHS number" do
      let!(:patient) { create(:patient, nhs_number:) }

      it { should include(patient) }

      context "when other patients match too" do
        let(:other_patient) do
          create(:patient, first_name:, last_name:, date_of_birth:)
        end

        it { should_not include(other_patient) }
      end
    end

    context "with matching first name, last name and date of birth" do
      let(:patient) do
        create(:patient, first_name:, last_name:, date_of_birth:)
      end

      it { should include(patient) }
    end

    context "with matching first name, last name and postcode" do
      let(:patient) do
        create(:patient, first_name:, last_name:, address_postcode:)
      end

      it { should include(patient) }
    end

    context "with matching first name, date of birth and postcode" do
      let(:patient) do
        create(:patient, first_name:, date_of_birth:, address_postcode:)
      end

      it { should include(patient) }
    end

    context "with matching last name, date of birth and postcode" do
      let(:patient) do
        create(:patient, last_name:, date_of_birth:, address_postcode:)
      end

      it { should include(patient) }
    end
  end

  describe "#year_group" do
    subject { patient.year_group }

    around { |example| travel_to(date) { example.run } }

    let(:patient) { described_class.new(date_of_birth: dob) }

    context "child born BEFORE 1 Sep 2016, date is BEFORE 1 Sep 2024" do
      let(:dob) { Date.new(2016, 8, 31) }
      let(:date) { Date.new(2024, 8, 31) }

      it { should eq 3 }
    end

    context "child born BEFORE 1 Sep 2016, date is AFTER 1 Sep 2024" do
      let(:dob) { Date.new(2016, 8, 31) }
      let(:date) { Date.new(2024, 9, 1) }

      it { should eq 4 }
    end

    context "child born AFTER 1 Sep 2016, date is BEFORE 1 Sep 2024" do
      let(:dob) { Date.new(2016, 9, 1) }
      let(:date) { Date.new(2024, 8, 31) }

      it { should eq 2 }
    end

    context "child born AFTER 1 Sep 2016, date is AFTER 1 Sep 2024" do
      let(:dob) { Date.new(2016, 9, 1) }
      let(:date) { Date.new(2024, 9, 1) }

      it { should eq 3 }
    end
  end

  describe "#stage_changes" do
    let(:patient) { create(:patient, first_name: "John", last_name: "Doe") }

    it "stages new changes in pending_changes" do
      patient.stage_changes(first_name: "Jane", address_line_1: "123 New St")

      expect(patient.pending_changes).to eq(
        { "first_name" => "Jane", "address_line_1" => "123 New St" }
      )
    end

    it "does not stage unchanged attributes" do
      patient.stage_changes(first_name: "John", last_name: "Smith")

      expect(patient.pending_changes).to eq({ "last_name" => "Smith" })
    end

    it "does not stage blank values" do
      patient.stage_changes(
        first_name: "",
        last_name: nil,
        address_line_1: "123 New St"
      )

      expect(patient.pending_changes).to eq(
        { "address_line_1" => "123 New St" }
      )
    end

    it "updates the pending_changes attribute" do
      expect { patient.stage_changes(first_name: "Jane") }.to change {
        patient.reload.pending_changes
      }.from({}).to({ "first_name" => "Jane" })
    end

    it "does not update other attributes directly" do
      patient.stage_changes(first_name: "Jane", last_name: "Smith")

      expect(patient.first_name).to eq("John")
      expect(patient.last_name).to eq("Doe")
    end

    it "does not save any changes if no valid changes are provided" do
      expect { patient.stage_changes(first_name: "John") }.not_to(
        change { patient.reload.pending_changes }
      )
    end
  end

  describe "#with_pending_changes" do
    let(:patient) { create(:patient) }

    it "returns the patient with pending changes applied" do
      patient.stage_changes(first_name: "Jane")
      expect(patient.first_name_changed?).to be(false)

      changed_patient = patient.with_pending_changes
      expect(changed_patient.first_name_changed?).to be(true)
      expect(changed_patient.last_name_changed?).to be(false)
      expect(changed_patient.first_name).to eq("Jane")
    end
  end
end
