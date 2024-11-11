# frozen_string_literal: true

# == Schema Information
#
# Table name: session_attendances
#
#  id                 :bigint           not null, primary key
#  attending          :boolean          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  patient_session_id :bigint           not null
#  session_date_id    :bigint           not null
#
# Indexes
#
#  index_session_attendances_on_patient_session_id  (patient_session_id)
#  index_session_attendances_on_session_date_id     (session_date_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_session_id => patient_sessions.id)
#  fk_rails_...  (session_date_id => session_dates.id)
#
class SessionAttendance < ApplicationRecord
  belongs_to :patient_session
  belongs_to :session_date
end
