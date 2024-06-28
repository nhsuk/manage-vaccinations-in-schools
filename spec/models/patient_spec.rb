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
#  last_name                :string
#  nhs_number               :string
#  sent_consent_at          :datetime
#  sent_reminder_at         :datetime
#  session_reminder_sent_at :datetime
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  location_id              :bigint
#  parent_id                :bigint
#
# Indexes
#
#  index_patients_on_location_id  (location_id)
#  index_patients_on_nhs_number   (nhs_number) UNIQUE
#  index_patients_on_parent_id    (parent_id)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id)
#  fk_rails_...  (parent_id => parents.id)
#
require "rails_helper"

describe Patient do
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
