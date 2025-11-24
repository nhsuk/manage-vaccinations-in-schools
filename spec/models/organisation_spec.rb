# frozen_string_literal: true

# == Schema Information
#
# Table name: organisations
#
#  id         :bigint           not null, primary key
#  ods_code   :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_organisations_on_ods_code  (ods_code) UNIQUE
#
describe Organisation do
  subject(:organisation) { build(:organisation) }

  it_behaves_like "a Flipper actor"

  describe "associations" do
    it { should have_many(:teams) }
  end

  describe "normalizations" do
    it { should normalize(:ods_code).from(" r1a ").to("R1A") }
  end

  describe "validations" do
    it { should validate_presence_of(:ods_code) }
    it { should validate_uniqueness_of(:ods_code).ignoring_case_sensitivity }
  end
end
