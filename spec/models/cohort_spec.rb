# frozen_string_literal: true

# == Schema Information
#
# Table name: cohorts
#
#  id                      :bigint           not null, primary key
#  reception_starting_year :integer          not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  team_id                 :bigint           not null
#
# Indexes
#
#  index_cohorts_on_team_id                              (team_id)
#  index_cohorts_on_team_id_and_reception_starting_year  (team_id,reception_starting_year) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#
describe Cohort do
  subject(:cohort) { build(:cohort) }

  describe "validations" do
    it { should be_valid }
  end

  describe "#year_group" do
    subject(:year_group) do
      build(:cohort, reception_starting_year: 2000).year_group
    end

    around { |example| travel_to(today) { example.run } }

    context "when the date is the first day of reception" do
      let(:today) { Date.new(2000, 9, 1) }

      it { should eq(0) }
    end

    context "when the date is the last day of reception" do
      let(:today) { Date.new(2001, 8, 31) }

      it { should eq(0) }
    end

    context "when the date is the first day of year 1" do
      let(:today) { Date.new(2001, 9, 1) }

      it { should eq(1) }
    end
  end
end
