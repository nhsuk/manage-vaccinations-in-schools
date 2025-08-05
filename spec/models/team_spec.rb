# frozen_string_literal: true

# == Schema Information
#
# Table name: teams
#
#  id                            :bigint           not null, primary key
#  careplus_venue_code           :string           not null
#  days_before_consent_reminders :integer          default(7), not null
#  days_before_consent_requests  :integer          default(21), not null
#  days_before_invitations       :integer          default(21), not null
#  email                         :string
#  name                          :text             not null
#  ods_code                      :string           not null
#  phone                         :string
#  phone_instructions            :string
#  privacy_notice_url            :string           not null
#  privacy_policy_url            :string           not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  reply_to_id                   :uuid
#
# Indexes
#
#  index_teams_on_name      (name) UNIQUE
#  index_teams_on_ods_code  (ods_code) UNIQUE
#

describe Team do
  subject(:team) { build(:team) }

  describe "validations" do
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:ods_code) }
    it { should validate_presence_of(:phone) }
    it { should validate_presence_of(:privacy_policy_url) }

    it { should validate_uniqueness_of(:name) }
    it { should validate_uniqueness_of(:ods_code).ignoring_case_sensitivity }
  end

  it { should normalize(:ods_code).from(" r1a ").to("R1A") }

  it_behaves_like "a model with a normalised email address"
  it_behaves_like "a model with a normalised phone number"

  describe "#community_clinics" do
    let(:clinic_locations) { create_list(:community_clinic, 3, team:) }

    it "returns the clinic locations" do
      expect(team.community_clinics).to match_array(clinic_locations)
    end
  end
end
