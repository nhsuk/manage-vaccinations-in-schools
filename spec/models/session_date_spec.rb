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
  subject(:session_date) { build(:session_date, session:) }

  let(:session) { create(:session, academic_year: 2024) }

  describe "validations" do
    it "validates that the date is within the academic year" do
      expect(session_date).to validate_comparison_of(
        :value
      ).is_greater_than_or_equal_to(
        Date.new(2024, 9, 1)
      ).is_less_than_or_equal_to(Date.new(2025, 8, 31))
    end
  end
end