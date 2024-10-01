# frozen_string_literal: true

# == Schema Information
#
# Table name: session_notifications
#
#  id           :bigint           not null, primary key
#  sent_at      :datetime         not null
#  session_date :date             not null
#  patient_id   :bigint           not null
#  session_id   :bigint           not null
#
# Indexes
#
#  idx_on_patient_id_session_id_session_date_f7f30a3aa3  (patient_id,session_id,session_date)
#  index_session_notifications_on_patient_id             (patient_id)
#  index_session_notifications_on_session_id             (session_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (session_id => sessions.id)
#
class SessionNotification < ApplicationRecord
  belongs_to :patient
  belongs_to :session
end
