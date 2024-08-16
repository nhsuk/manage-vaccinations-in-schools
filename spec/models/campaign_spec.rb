# frozen_string_literal: true

# == Schema Information
#
# Table name: campaigns
#
#  id            :bigint           not null, primary key
#  academic_year :integer
#  active        :boolean          default(FALSE), not null
#  end_date      :date
#  name          :string
#  start_date    :date
#  type          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  team_id       :integer          not null
#
# Indexes
#
#  index_campaigns_on_name_and_type_and_academic_year_and_team_id  (name,type,academic_year,team_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#
require "rails_helper"

describe Campaign, type: :model do
  subject(:campaign) do
    build(:campaign, academic_year: 2024, start_date: Date.new(2024, 6, 1))
  end

  it { should normalize(:name).from(" abc ").to("abc") }

  describe "validations" do
    it { should validate_presence_of(:name).on(:update) }

    it { should validate_presence_of(:type).on(:update) }
    it { should validate_inclusion_of(:type).in_array(%w[flu hpv]) }

    it { should validate_presence_of(:academic_year).on(:update) }

    it do
      expect(campaign).to validate_comparison_of(
        :academic_year
      ).is_greater_than_or_equal_to(2000).is_less_than_or_equal_to(
        Time.zone.today.year + 5
      )
    end

    it { should validate_presence_of(:start_date).on(:update) }

    it do
      expect(campaign).to validate_comparison_of(
        :start_date
      ).is_greater_than_or_equal_to(Date.new(2024, 1, 1))
    end

    it { should validate_presence_of(:end_date).on(:update) }

    it do
      expect(campaign).to validate_comparison_of(
        :end_date
      ).is_greater_than_or_equal_to(
        Date.new(2024, 6, 1)
      ).is_less_than_or_equal_to(Date.new(2025, 12, 31))
    end

    context "when vaccines don't match type" do
      subject(:campaign) do
        build(:campaign, type: "flu", vaccines: [build(:vaccine, type: "hpv")])
      end

      it "is invalid" do
        expect(campaign).to be_invalid
        expect(campaign.errors[:vaccines]).to include(
          "must match programme type"
        )
      end
    end
  end
end
