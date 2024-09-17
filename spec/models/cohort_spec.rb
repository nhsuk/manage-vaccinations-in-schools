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
    it do
      expect(cohort).to validate_comparison_of(
        :reception_starting_year
      ).is_greater_than_or_equal_to(1990)
    end
  end

  describe "scopes" do
    describe "#for_year_groups" do
      subject(:scope) { described_class.for_year_groups(year_groups) }

      let(:year_groups) { [1, 2, 3] }
      let(:today) { Date.new(2000, 9, 1) }

      let!(:year_one) { create(:cohort, reception_starting_year: 1999) }
      let!(:year_two) { create(:cohort, reception_starting_year: 1998) }
      let!(:year_three) { create(:cohort, reception_starting_year: 1997) }

      before do
        create(:cohort, reception_starting_year: 2000) # reception
        create(:cohort, reception_starting_year: 1996) # year 4
      end

      around { |example| travel_to(today) { example.run } }

      it { should contain_exactly(year_one, year_two, year_three) }
    end
  end

  describe "#find_or_create_by_date_of_birth!" do
    subject(:find_or_create_by_date_of_birth!) do
      described_class.find_or_create_by_date_of_birth!(date_of_birth, team:)
    end

    let(:team) { build(:team) }

    context "with a date of birth before September" do
      let(:date_of_birth) { Date.new(2000, 8, 31) }

      it { should have_attributes(team:, reception_starting_year: 2004) }
    end

    context "with a date of birth after September" do
      let(:date_of_birth) { Date.new(2000, 9, 1) }

      it { should have_attributes(team:, reception_starting_year: 2005) }
    end
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
