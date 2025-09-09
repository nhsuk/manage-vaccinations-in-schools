# frozen_string_literal: true

# == Schema Information
#
# Table name: session_attendances
#
#  id              :bigint           not null, primary key
#  attending       :boolean          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  patient_id      :bigint           not null
#  session_date_id :bigint           not null
#
# Indexes
#
#  index_session_attendances_on_patient_id                      (patient_id)
#  index_session_attendances_on_patient_id_and_session_date_id  (patient_id,session_date_id) UNIQUE
#  index_session_attendances_on_session_date_id                 (session_date_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (session_date_id => session_dates.id)
#
class SessionAttendance < ApplicationRecord
  audited associated_with: :patient

  belongs_to :patient
  belongs_to :session_date

  has_one :session, through: :session_date
  has_one :location, through: :session

  scope :today, -> { joins(:session_date).merge(SessionDate.today) }

  delegate :today?, to: :session_date
end
