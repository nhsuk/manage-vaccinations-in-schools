# frozen_string_literal: true

# == Schema Information
#
# Table name: identity_checks
#
#  id                              :bigint           not null, primary key
#  confirmed_by_other_name         :string           default(""), not null
#  confirmed_by_other_relationship :string           default(""), not null
#  confirmed_by_patient            :boolean          not null
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  vaccination_record_id           :bigint           not null
#
# Indexes
#
#  index_identity_checks_on_vaccination_record_id  (vaccination_record_id)
#
# Foreign Keys
#
#  fk_rails_...  (vaccination_record_id => vaccination_records.id) ON DELETE => cascade
#
describe IdentityCheck do
  describe "associations" do
    it { should belong_to(:vaccination_record) }
  end

  describe "scopes" do
    let(:confirmed_by_patient) do
      create(:identity_check, :confirmed_by_patient)
    end
    let(:confirmed_by_other) { create(:identity_check, :confirmed_by_other) }

    describe "#confirmed_by_patient" do
      subject(:scope) { described_class.confirmed_by_patient }

      it { should include(confirmed_by_patient) }
      it { should_not include(confirmed_by_other) }
    end

    describe "#confirmed_by_other" do
      subject(:scope) { described_class.confirmed_by_other }

      it { should include(confirmed_by_other) }
      it { should_not include(confirmed_by_patient) }
    end
  end

  describe "validations" do
    context "when confirmed by patient" do
      subject { build(:identity_check, :confirmed_by_patient) }

      it { should validate_absence_of(:confirmed_by_other_name) }
      it { should validate_absence_of(:confirmed_by_other_relationship) }
    end

    context "when confirmed by someone else" do
      subject { build(:identity_check, :confirmed_by_other) }

      it { should validate_presence_of(:confirmed_by_other_name) }
      it { should validate_presence_of(:confirmed_by_other_relationship) }
    end
  end

  describe "#confirmed_by_patient?" do
    subject { identity_check.confirmed_by_patient? }

    context "when confirmed by patient" do
      let(:identity_check) { build(:identity_check, :confirmed_by_patient) }

      it { should be(true) }
    end

    context "when confirmed by someone else" do
      let(:identity_check) { build(:identity_check, :confirmed_by_other) }

      it { should be(false) }
    end
  end

  describe "#confirmed_by_other?" do
    subject { identity_check.confirmed_by_other? }

    context "when confirmed by patient" do
      let(:identity_check) { build(:identity_check, :confirmed_by_patient) }

      it { should be(false) }
    end

    context "when confirmed by someone else" do
      let(:identity_check) { build(:identity_check, :confirmed_by_other) }

      it { should be(true) }
    end
  end
end
