# frozen_string_literal: true

# == Schema Information
#
# Table name: organisations
#
#  id                            :bigint           not null, primary key
#  days_before_consent_reminders :integer          default(7), not null
#  days_before_consent_requests  :integer          default(21), not null
#  days_before_invitations       :integer          default(21), not null
#  email                         :string
#  name                          :text             not null
#  ods_code                      :string           not null
#  phone                         :string
#  privacy_policy_url            :string
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  reply_to_id                   :uuid
#
# Indexes
#
#  index_organisations_on_name      (name) UNIQUE
#  index_organisations_on_ods_code  (ods_code) UNIQUE
#

describe Organisation do
  subject(:organisation) { build(:organisation) }

  describe "validations" do
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:ods_code) }
    it { should validate_presence_of(:phone) }

    it { should validate_uniqueness_of(:name) }
    it { should validate_uniqueness_of(:ods_code).ignoring_case_sensitivity }
  end

  it { should normalize(:ods_code).from(" r1a ").to("R1A") }

  describe "#community_clinics" do
    let(:clinic_locations) do
      create_list(:location, 3, :community_clinic, organisation:)
    end

    it "returns the clinic locations" do
      expect(organisation.community_clinics).to eq(clinic_locations)
    end
  end
end
