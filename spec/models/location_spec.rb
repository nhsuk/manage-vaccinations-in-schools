# frozen_string_literal: true

# == Schema Information
#
# Table name: locations
#
#  id               :bigint           not null, primary key
#  address          :text
#  county           :text
#  locality         :text
#  name             :text             not null
#  postcode         :text
#  town             :text
#  type             :integer          not null
#  url              :text
#  urn              :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  imported_from_id :bigint
#
# Indexes
#
#  index_locations_on_imported_from_id  (imported_from_id)
#  index_locations_on_urn               (urn) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (imported_from_id => immunisation_imports.id)
#
require "rails_helper"

describe Location, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }

    context "with a generic clinic" do
      subject(:location) { build(:location, :generic_clinic) }

      it { should_not validate_presence_of(:urn) }
      it { should validate_uniqueness_of(:urn) }
    end

    context "with a school" do
      subject(:location) { build(:location, :school, urn: "abc") }

      it { should validate_presence_of(:urn) }
      it { should validate_uniqueness_of(:urn) }
    end
  end
end