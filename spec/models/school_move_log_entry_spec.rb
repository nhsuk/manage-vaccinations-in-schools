# frozen_string_literal: true

# == Schema Information
#
# Table name: school_move_log_entries
#
#  id             :bigint           not null, primary key
#  home_educated  :boolean
#  move_to_school :boolean
#  created_at     :datetime         not null
#  patient_id     :bigint           not null
#  school_id      :bigint
#  user_id        :bigint
#
# Indexes
#
#  index_school_move_log_entries_on_patient_id  (patient_id)
#  index_school_move_log_entries_on_school_id   (school_id)
#  index_school_move_log_entries_on_user_id     (user_id)
#
describe SchoolMoveLogEntry do
  subject(:school_move_log_entry) { build(:school_move_log_entry) }

  it { should be_valid }
end
