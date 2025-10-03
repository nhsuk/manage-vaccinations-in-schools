# frozen_string_literal: true

# == Schema Information
#
# Table name: access_log_entries
#
#  id         :bigint           not null, primary key
#  action     :integer          not null
#  controller :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  patient_id :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_access_log_entries_on_patient_id  (patient_id)
#  index_access_log_entries_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (user_id => users.id)
#
class AccessLogEntry < ApplicationRecord
  belongs_to :user
  belongs_to :patient

  enum :controller,
       { patients: 0, patient_sessions: 1, timeline: 2, graph: 3 },
       validate: true

  enum :action, { show: 0, log: 1, show_pii: 2 }, validate: true
end
