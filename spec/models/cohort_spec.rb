# frozen_string_literal: true

# == Schema Information
#
# Table name: cohorts
#
#  id                  :bigint           not null, primary key
#  birth_academic_year :integer          not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  organisation_id     :bigint           not null
#
# Indexes
#
#  index_cohorts_on_organisation_id                          (organisation_id)
#  index_cohorts_on_organisation_id_and_birth_academic_year  (organisation_id,birth_academic_year) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#
describe Cohort do
  subject(:cohort) { build(:cohort) }

  describe "scopes" do
    describe "#for_year_groups" do
      subject(:scope) { described_class.for_year_groups(year_groups) }

      let(:year_groups) { [1, 2, 3] }
      let(:today) { Date.new(2005, 9, 1) }

      let!(:year_one) { create(:cohort, birth_academic_year: 1999) }
      let!(:year_two) { create(:cohort, birth_academic_year: 1998) }
      let!(:year_three) { create(:cohort, birth_academic_year: 1997) }

      before do
        create(:cohort, birth_academic_year: 2000) # reception
        create(:cohort, birth_academic_year: 1996) # year 4
      end

      around { |example| travel_to(today) { example.run } }

      it { should contain_exactly(year_one, year_two, year_three) }
    end
  end

  describe "validations" do
    it do
      expect(cohort).to validate_comparison_of(
        :birth_academic_year
      ).is_greater_than_or_equal_to(1990)
    end
  end

  describe "#year_group" do
    subject(:year_group) do
      build(:cohort, birth_academic_year: 2000).year_group
    end

    around { |example| travel_to(today) { example.run } }

    context "when the date is the first day of reception" do
      let(:today) { Date.new(2005, 9, 1) }

      it { should eq(0) }
    end

    context "when the date is the last day of reception" do
      let(:today) { Date.new(2006, 8, 31) }

      it { should eq(0) }
    end

    context "when the date is the first day of year 1" do
      let(:today) { Date.new(2006, 9, 1) }

      it { should eq(1) }
    end
  end
end
