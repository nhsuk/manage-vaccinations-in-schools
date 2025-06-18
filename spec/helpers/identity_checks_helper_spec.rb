# frozen_string_literal: true

describe IdentityChecksHelper do
  describe "#identity_check_label" do
    subject { helper.identity_check_label(identity_check) }

    context "when confirmed by the patient" do
      let(:identity_check) { create(:identity_check, :confirmed_by_patient) }

      it { should eq("The child") }
    end

    context "when confirmed by someone else" do
      let(:identity_check) do
        create(
          :identity_check,
          :confirmed_by_other,
          confirmed_by_other_name: "Arthur Dent",
          confirmed_by_other_relationship: "Friend"
        )
      end

      it { should eq("Arthur Dent (Friend)") }
    end
  end
end
