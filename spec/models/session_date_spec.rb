# frozen_string_literal: true

# == Schema Information
#
# Table name: session_dates
#
#  id         :bigint           not null, primary key
#  value      :date             not null
#  session_id :bigint           not null
#
# Indexes
#
#  index_session_dates_on_session_id            (session_id)
#  index_session_dates_on_session_id_and_value  (session_id,value) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (session_id => sessions.id)
#
describe SessionDate do
  subject(:session_date) { build(:session_date, session:, value:) }

  let(:session) { create(:session, academic_year: 2024) }
  let(:value) { Date.current }

  describe "validations" do
    it "validates that the date is within the academic year" do
      expect(session_date).to validate_comparison_of(
        :value
      ).is_greater_than_or_equal_to(
        Date.new(2024, 9, 1)
      ).is_less_than_or_equal_to(Date.new(2025, 8, 31))
    end
  end

  describe "#today_or_future?" do
    subject(:today_or_future?) { session_date.today_or_future? }

    context "with a today's date" do
      it { should be(true) }
    end

    context "with a date in the past" do
      let(:value) { Date.yesterday }

      it { should be(false) }
    end

    context "with a date in the future" do
      let(:value) { Date.tomorrow }

      it { should be(true) }
    end
  end
end
