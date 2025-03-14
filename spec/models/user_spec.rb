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
#  fallback_role       :integer          default("nurse"), not null
#  family_name         :string           not null
#  given_name          :string           not null
#  last_sign_in_at     :datetime
#  last_sign_in_ip     :string
#  provider            :string
#  remember_created_at :datetime
#  session_token       :string
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

  it_behaves_like "a model with a normalised email address"

  describe "validations" do
    it { should validate_presence_of(:given_name) }
    it { should validate_presence_of(:family_name) }
    it { should validate_length_of(:given_name).is_at_most(255) }
    it { should validate_length_of(:family_name).is_at_most(255) }
  end

  describe "#selected_organisation" do
    subject(:selected_organisation) { user.selected_organisation }

    context "cis2 is enabled", cis2: :enabled do
      let(:organisation) { create(:organisation) }
      let(:user) { create(:user, organisation:) }

      it { should eq(organisation) }
    end
  end

  describe "#is_admin?" do
    subject(:is_admin?) { user.is_admin? }

    context "cis2 is enabled", cis2: :enabled do
      context "when the user is an admin" do
        let(:user) { build(:admin) }

        it { should be true }
      end

      context "when the user is a nurse" do
        let(:user) { build(:nurse) }

        it { should be false }
      end

      context "when the user is a nurse and superuser" do
        let(:user) { build(:nurse, :superuser) }

        it { should be false }
      end
    end

    context "cis2 is disabled", cis2: :disabled do
      context "when the user is an admin" do
        let(:user) { build(:admin) }

        it { should be true }
      end

      context "when the user is an admin and superuser" do
        let(:user) { build(:admin, :superuser) }

        it { should be true }
      end

      context "when the user is a nurse" do
        let(:user) { build(:nurse) }

        it { should be false }
      end
    end
  end

  describe "#is_nurse?" do
    subject(:is_nurse?) { user.is_nurse? }

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

  describe "#is_superuser?" do
    subject(:is_superuser?) { user.is_superuser? }

    context "cis2 is enabled", cis2: :enabled do
      context "when the user is an admin" do
        let(:user) { build(:admin) }

        it { should be false }

        context "with superuser access" do
          let(:user) { build(:admin, :superuser) }

          it { should be true }
        end

        context "without workgroups" do
          let(:user) { build(:admin, selected_role_workgroups: nil) }

          it { should be false }
        end
      end

      context "when the user is a nurse" do
        let(:user) { build(:nurse) }

        it { should be false }

        context "with superuser access" do
          let(:user) { build(:nurse, :superuser) }

          it { should be true }
        end

        context "without workgroups" do
          let(:user) { build(:nurse, selected_role_workgroups: nil) }

          it { should be false }
        end
      end
    end

    context "cis2 is disabled", cis2: :disabled do
      context "when the user is an admin" do
        let(:user) { build(:admin) }

        it { should be false }

        context "with superuser access" do
          let(:user) { build(:admin, :superuser) }

          it { should be true }
        end
      end

      context "when the user is a nurse" do
        let(:user) { build(:nurse) }

        it { should be false }

        context "with superuser access" do
          let(:user) { build(:nurse, :superuser) }

          it { should be true }
        end
      end
    end
  end
end
