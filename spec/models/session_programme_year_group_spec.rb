# frozen_string_literal: true

# == Schema Information
#
# Table name: session_programme_year_groups
#
#  programme_type :enum             not null, primary key
#  year_group     :integer          not null, primary key
#  session_id     :bigint           not null, primary key
#
# Indexes
#
#  index_session_programme_year_groups_on_session_id  (session_id)
#
# Foreign Keys
#
#  fk_rails_...  (session_id => sessions.id) ON DELETE => cascade
#
describe SessionProgrammeYearGroup do
  subject { build(:session_programme_year_group) }

  it { should be_valid }

  describe "associations" do
    it { should belong_to(:session) }
  end
end
