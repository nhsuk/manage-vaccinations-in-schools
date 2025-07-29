# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                          :bigint           not null, primary key
#  current_sign_in_at          :datetime
#  current_sign_in_ip          :string
#  email                       :string
#  encrypted_password          :string           default(""), not null
#  fallback_role               :integer
#  family_name                 :string           not null
#  given_name                  :string           not null
#  last_sign_in_at             :datetime
#  last_sign_in_ip             :string
#  provider                    :string
#  remember_created_at         :datetime
#  reporting_api_session_token :string
#  session_token               :string
#  show_in_suppliers           :boolean          default(FALSE), not null
#  sign_in_count               :integer          default(0), not null
#  uid                         :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#
# Indexes
#
#  index_users_on_email                        (email) UNIQUE
#  index_users_on_provider_and_uid             (provider,uid) UNIQUE
#  index_users_on_reporting_api_session_token  (reporting_api_session_token) UNIQUE
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

  describe "#selected_team" do
    subject(:selected_team) { user.selected_team }

    context "cis2 is enabled", cis2: :enabled do
      let(:team) { create(:team) }
      let(:user) { create(:user, team:) }

      it { should eq(team) }
    end
  end

  describe "#role_description" do
    subject { user.role_description }

    context "when the user is a medical secretary" do
      let(:user) { build(:medical_secretary) }

      it { should eq("Medical secretary") }
    end

    context "when the user is a nurse" do
      let(:user) { build(:nurse) }

      it { should eq("Nurse") }
    end

    context "when the user is a superuser" do
      let(:user) { build(:medical_secretary, :superuser) }

      it { should eq("Medical secretary (Superuser)") }
    end
  end

  describe "#is_medical_secretary?" do
    subject { user.is_medical_secretary? }

    context "cis2 is enabled", cis2: :enabled do
      context "when the user is a medical secretary" do
        let(:user) { build(:medical_secretary) }

        it { should be(true) }
      end

      context "when the user is an admin and superuser" do
        let(:user) { build(:medical_secretary, :superuser) }

        it { should be(true) }
      end

      context "when the user is a nurse" do
        let(:user) { build(:nurse) }

        it { should be(false) }
      end
    end

    context "cis2 is disabled", cis2: :disabled do
      context "when the user is a medical secretary" do
        let(:user) { build(:medical_secretary) }

        it { should be(true) }
      end

      context "when the user is an admin and superuser" do
        let(:user) { build(:medical_secretary, :superuser) }

        it { should be(false) }
      end

      context "when the user is a nurse" do
        let(:user) { build(:nurse) }

        it { should be(false) }
      end
    end
  end

  describe "#is_nurse?" do
    subject { user.is_nurse? }

    context "cis2 is enabled", cis2: :enabled do
      context "when the user is a nurse" do
        let(:user) { build(:nurse) }

        it { should be(true) }
      end

      context "when the user is a medical secretary" do
        let(:user) { build(:medical_secretary) }

        it { should be(false) }
      end
    end

    context "cis2 is disabled", cis2: :disabled do
      context "when the user is a nurse" do
        let(:user) { build(:nurse) }

        it { should be(true) }
      end

      context "when the user is a medical secretary" do
        let(:user) { build(:medical_secretary) }

        it { should be(false) }
      end
    end
  end

  describe "#is_healthcare_assistant?" do
    subject { user.is_healthcare_assistant? }

    context "cis2 is enabled", cis2: :enabled do
      context "when the user is a nurse" do
        let(:user) { build(:nurse) }

        it { should be(false) }
      end

      context "when the user is a medical secretary" do
        let(:user) { build(:medical_secretary) }

        it { should be(false) }
      end

      context "when the user is a healthcare assistant" do
        let(:user) { build(:healthcare_assistant) }

        it { should be(true) }
      end
    end

    context "cis2 is disabled", cis2: :disabled do
      context "when the user is a nurse" do
        let(:user) { build(:nurse) }

        it { should be(false) }
      end

      context "when the user is a medical secretary" do
        let(:user) { build(:medical_secretary) }

        it { should be(false) }
      end

      context "when the user is a healthcare assistant" do
        let(:user) { build(:healthcare_assistant) }

        it { should be(true) }
      end
    end
  end

  describe "#is_prescriber?" do
    subject { user.is_prescriber? }

    context "cis2 is enabled", cis2: :enabled do
      context "when the user is a nurse" do
        let(:user) { build(:nurse) }

        it { should be(false) }
      end

      context "when the user is a medical secretary" do
        let(:user) { build(:medical_secretary) }

        it { should be(false) }
      end

      context "when the user is a prescriber" do
        let(:user) { build(:prescriber) }

        it { should be(true) }
      end
    end

    context "cis2 is disabled", cis2: :disabled do
      context "when the user is a nurse" do
        let(:user) { build(:nurse) }

        it { should be(false) }
      end

      context "when the user is a medical secretary" do
        let(:user) { build(:medical_secretary) }

        it { should be(false) }
      end

      context "when the user is a prescriber" do
        let(:user) { build(:prescriber) }

        it { should be(true) }
      end
    end
  end

  describe "#is_superuser?" do
    subject { user.is_superuser? }

    context "cis2 is enabled", cis2: :enabled do
      context "when the user is a medical secretary" do
        let(:user) { build(:medical_secretary) }

        it { should be(false) }

        context "with superuser access" do
          let(:user) { build(:medical_secretary, :superuser) }

          it { should be(true) }
        end
      end

      context "when the user is a nurse" do
        let(:user) { build(:nurse) }

        it { should be(false) }

        context "with superuser access" do
          let(:user) { build(:nurse, :superuser) }

          it { should be(true) }
        end
      end
    end

    context "cis2 is disabled", cis2: :disabled do
      context "when the user is a medical secretary" do
        let(:user) { build(:medical_secretary) }

        it { should be(false) }

        context "with superuser access" do
          let(:user) { build(:medical_secretary, :superuser) }

          it { should be(true) }
        end
      end

      context "when the user is a nurse" do
        let(:user) { build(:nurse) }

        it { should be(false) }

        context "with superuser access" do
          let(:user) { build(:nurse, :superuser) }

          it { should be(true) }
        end
      end
    end
  end

  describe "#is_support?" do
    subject(:is_support?) { user.is_support? }

    context "cis2 is enabled", cis2: :enabled do
      context "when the user is support" do
        let(:user) { build(:support) }

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

      context "when the user is an admin" do
        let(:user) { build(:admin) }

        it { should be false }
      end

      context "when the user is an admin and superuser" do
        let(:user) { build(:admin, :superuser) }

        it { should be false }
      end
    end

    context "cis2 is disabled", cis2: :disabled do
      context "when the user is support" do
        let(:user) { build(:support) }

        it { should be true }
      end

      context "when the user is an admin" do
        let(:user) { build(:admin) }

        it { should be false }
      end

      context "when the user is an admin and superuser" do
        let(:user) { build(:admin, :superuser) }

        it { should be false }
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
  end
end
