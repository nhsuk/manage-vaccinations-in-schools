# frozen_string_literal: true

# == Schema Information
#
# Table name: campaigns
#
#  id            :bigint           not null, primary key
#  academic_year :integer          not null
#  name          :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  team_id       :integer
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#
require "rails_helper"

describe Campaign, type: :model do
  subject(:campaign) { build(:campaign) }

  describe "validations" do
    it { should validate_presence_of(:academic_year) }

    it do
      expect(campaign).to validate_comparison_of(
        :academic_year
      ).is_greater_than_or_equal_to(2000).is_less_than_or_equal_to(
        Time.zone.today.year + 5
      )
    end
  end
end
