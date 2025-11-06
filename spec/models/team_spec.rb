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
#  phone                         :string
#  phone_instructions            :string
#  privacy_notice_url            :string           not null
#  privacy_policy_url            :string           not null
#  type                          :integer          not null
#  workgroup                     :string           not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  organisation_id               :bigint           not null
#  reply_to_id                   :uuid
#
# Indexes
#
#  index_teams_on_name             (name) UNIQUE
#  index_teams_on_organisation_id  (organisation_id)
#  index_teams_on_workgroup        (workgroup) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#

describe Team do
  subject(:team) { build(:team) }

  describe "associations" do
    it { should belong_to(:organisation) }
    it { should have_many(:archive_reasons) }
  end

  describe "validations" do
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:phone) }
    it { should validate_presence_of(:privacy_policy_url) }
    it { should validate_presence_of(:workgroup) }

    it do
      expect(team).to validate_inclusion_of(:type).in_array(
        %w[poc_only upload_only poc_with_legacy_upload]
      )
    end

    it { should validate_uniqueness_of(:name) }
    it { should validate_uniqueness_of(:workgroup) }
  end

  it_behaves_like "a model with a normalised email address"
  it_behaves_like "a model with a normalised phone number"

  describe "#community_clinics" do
    let(:clinic_locations) { create_list(:community_clinic, 3, team:) }

    it "returns the clinic locations" do
      expect(team.community_clinics).to match_array(clinic_locations)
    end
  end

  describe "#has_upload_access_only?" do
    subject { team.has_upload_access_only? }

    context "given the bulk upload feature flag is disabled" do
      context "when type is upload_only" do
        before { team.type = :upload_only }

        it { should be false }
      end

      context "when type is poc_only" do
        before { team.type = :poc_only }

        it { should be false }
      end
    end

    context "given the bulk upload feature flag is enabled" do
      before { Flipper.enable(:bulk_upload) }

      context "when type is upload_only" do
        before { team.type = :upload_only }

        it { should be true }
      end

      context "when type is poc_only" do
        before { team.type = :poc_only }

        it { should be false }
      end

      context "when type is poc_with_legacy_upload" do
        before { team.type = :poc_with_legacy_upload }

        it { should be false }
      end
    end
  end

  describe "#has_poc_access?" do
    subject { team.has_poc_access? }

    context "given the bulk upload feature flag is disabled" do
      context "when type is poc_only" do
        before { team.type = :poc_only }

        it { should be true }
      end

      context "when type is upload_only" do
        before { team.type = :upload_only }

        it { should be true }
      end
    end

    context "given the bulk upload feature flag is enabled" do
      before { Flipper.enable(:bulk_upload) }

      context "when type is poc_only" do
        before { team.type = :poc_only }

        it { should be true }
      end

      context "when type is poc_with_legacy_upload" do
        before { team.type = :poc_with_legacy_upload }

        it { should be true }
      end

      context "when type is upload_only" do
        before { team.type = :upload_only }

        it { should be false }
      end
    end
  end
end
