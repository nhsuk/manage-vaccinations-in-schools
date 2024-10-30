# frozen_string_literal: true

# == Schema Information
#
# Table name: batches
#
#  id              :bigint           not null, primary key
#  archived_at     :datetime
#  expiry          :date             not null
#  name            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organisation_id :bigint           not null
#  vaccine_id      :bigint           not null
#
# Indexes
#
#  idx_on_organisation_id_name_expiry_vaccine_id_6d9ae30338  (organisation_id,name,expiry,vaccine_id) UNIQUE
#  index_batches_on_organisation_id                          (organisation_id)
#  index_batches_on_vaccine_id                               (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#  fk_rails_...  (vaccine_id => vaccines.id)
#
describe Batch do
  subject(:batch) { build(:batch) }

  describe "scopes" do
    let(:archived_batch) { create(:batch, :archived) }
    let(:unarchived_batch) { create(:batch) }

    describe "#archived" do
      subject(:scope) { described_class.archived }

      it { should include(archived_batch) }
      it { should_not include(unarchived_batch) }
    end

    describe "#unarchived" do
      subject(:scope) { described_class.unarchived }

      it { should include(unarchived_batch) }
      it { should_not include(archived_batch) }
    end
  end

  describe "validations" do
    it { should be_valid }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:expiry) }

    it do
      travel_to(Date.new(2024, 9, 1)) do
        expect(batch).to validate_comparison_of(:expiry).is_greater_than(
          Date.new(2009, 1, 1)
        )
        expect(batch).to validate_comparison_of(:expiry).is_less_than(
          Date.new(2039, 1, 1)
        )
      end
    end

    it do
      expect(subject).to validate_uniqueness_of(:expiry).scoped_to(
        :organisation_id,
        :name,
        :vaccine_id
      )
    end

    context "with invalid characters" do
      subject(:batch) { build(:batch, name: "ABC*123") }

      it { should be_invalid }
    end
  end

  describe "#archived?" do
    subject(:archived?) { batch.archived? }

    it { should be(false) }

    context "when archived_at is set" do
      let(:batch) { build(:batch, archived_at: Date.new(2020, 1, 1)) }

      it { should be(true) }
    end
  end

  describe "#unarchived?" do
    subject(:unarchived?) { batch.unarchived? }

    it { should be(true) }

    context "when archived_at is set" do
      let(:batch) { build(:batch, archived_at: Date.new(2020, 1, 1)) }

      it { should be(false) }
    end
  end

  describe "#archive!" do
    subject(:archive!) { batch.archive! }

    it "sets the archived_at field" do
      expect { archive! }.to change(batch, :archived_at).from(nil)
    end

    context "when already archived" do
      let(:batch) { create(:batch, :archived) }

      it "doesn't change archived_at" do
        expect { archive! }.not_to change(batch, :archived_at)
      end
    end
  end
end
