# frozen_string_literal: true

# == Schema Information
#
# Table name: patients
#
#  id                       :bigint           not null, primary key
#  address_line_1           :string
#  address_line_2           :string
#  address_postcode         :string
#  address_town             :string
#  common_name              :string
#  date_of_birth            :date
#  first_name               :string
#  gender_code              :integer          default("not_known"), not null
#  home_educated            :boolean
#  last_name                :string
#  nhs_number               :string
#  sent_consent_at          :datetime
#  sent_reminder_at         :datetime
#  session_reminder_sent_at :datetime
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  imported_from_id         :bigint
#  parent_id                :bigint
#  school_id                :bigint
#
# Indexes
#
#  index_patients_on_imported_from_id  (imported_from_id)
#  index_patients_on_nhs_number        (nhs_number) UNIQUE
#  index_patients_on_parent_id         (parent_id)
#  index_patients_on_school_id         (school_id)
#
# Foreign Keys
#
#  fk_rails_...  (imported_from_id => immunisation_imports.id)
#  fk_rails_...  (parent_id => parents.id)
#  fk_rails_...  (school_id => locations.id)
#
require "rails_helper"

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

  describe "#year_group" do
    subject { patient.year_group }

    before { Timecop.freeze(date) }
    after { Timecop.return }

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
end
