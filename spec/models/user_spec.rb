# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                  :bigint           not null, primary key
#  current_sign_in_at  :datetime
#  current_sign_in_ip  :string
#  email               :string
#  encrypted_password  :string           default(""), not null
#  family_name         :string           not null
#  given_name          :string           not null
#  last_sign_in_at     :datetime
#  last_sign_in_ip     :string
#  provider            :string
#  remember_created_at :datetime
#  sign_in_count       :integer          default(0), not null
#  uid                 :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_users_on_email             (email) UNIQUE
#  index_users_on_provider_and_uid  (provider,uid) UNIQUE
#

describe User do
  subject(:user) { build(:user) }

  describe "validations" do
    it { should validate_presence_of(:given_name) }
    it { should validate_presence_of(:family_name) }
    it { should validate_length_of(:given_name).is_at_most(255) }
    it { should validate_length_of(:family_name).is_at_most(255) }
  end

  describe "#selected_team" do
    subject { user.selected_team }

    context "cis2 is disabled", cis2: :disabled do
      let(:team) { build(:team) }
      let(:user) { build(:user, teams: [team]) }

      it { should eq user.teams.first }
    end

    context "cis2 is enabled", cis2: :enabled do
      let(:team) { create(:team) }
      let(:user) { create(:user, selected_team: team) }

      it { should eq team }
    end
  end

  describe "#is_admin?" do
    subject { user.is_admin? }

    context "cis2 is enabled", cis2: :enabled do
      context "when the user is an admin" do
        let(:user) { build(:admin) }

        it { should be true }
      end

      context "when the user is a nurse" do
        let(:user) { build(:nurse) }

        it { should be false }
      end
    end

    context "cis2 is disabled", cis2: :disabled do
      context "when the user is an admin" do
        let(:user) { build(:admin) }

        it { should be true }
      end

      context "when the user is a nurse" do
        let(:user) { build(:nurse) }

        it { should be false }
      end
    end
  end

  describe "#is_nurse?" do
    subject { user.is_nurse? }

    context "cis2 is enabled", cis2: :enabled do
      context "when the user is a nurse" do
        let(:user) { build(:nurse) }

        it { should be true }
      end

      context "when the user is admin staff" do
        let(:user) { build(:admin) }

        it { should be false }
      end
    end

    context "cis2 is disabled", cis2: :disabled do
      context "when the user is a nurse" do
        let(:user) { build(:nurse) }

        it { should be true }
      end

      context "when the user is admin staff" do
        let(:user) { build(:admin) }

        it { should be false }
      end
    end
  end
end
