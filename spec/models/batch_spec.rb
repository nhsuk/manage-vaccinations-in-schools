# frozen_string_literal: true

# == Schema Information
#
# Table name: batches
#
#  id         :bigint           not null, primary key
#  expiry     :date             not null
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  team_id    :bigint           not null
#  vaccine_id :bigint           not null
#
# Indexes
#
#  index_batches_on_team_id                                     (team_id)
#  index_batches_on_team_id_and_name_and_expiry_and_vaccine_id  (team_id,name,expiry,vaccine_id) UNIQUE
#  index_batches_on_vaccine_id                                  (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#  fk_rails_...  (vaccine_id => vaccines.id)
#
describe Batch do
  subject(:batch) { build(:batch) }

  describe "validations" do
    it { should be_valid }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:expiry) }

    it do
      expect(batch).to validate_comparison_of(
        :expiry
      ).is_greater_than_or_equal_to(Date.new(2000, 1, 1))
    end

    context "with invalid characters" do
      subject(:batch) { build(:batch, name: "ABC*123") }

      it { should be_invalid }
    end
  end
end
