# frozen_string_literal: true

# == Schema Information
#
# Table name: pre_screenings
#
#  id                   :bigint           not null, primary key
#  notes                :text             default(""), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  patient_session_id   :bigint           not null
#  performed_by_user_id :bigint           not null
#  programme_id         :bigint           not null
#
# Indexes
#
#  index_pre_screenings_on_patient_session_id    (patient_session_id)
#  index_pre_screenings_on_performed_by_user_id  (performed_by_user_id)
#  index_pre_screenings_on_programme_id          (programme_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_session_id => patient_sessions.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#  fk_rails_...  (programme_id => programmes.id)
#
class PreScreening < ApplicationRecord
  audited associated_with: :patient_session

  belongs_to :patient_session
  belongs_to :programme
  belongs_to :performed_by,
             class_name: "User",
             foreign_key: :performed_by_user_id

  has_one :patient, through: :patient_session

  scope :today, -> { where(created_at: Date.current.all_day) }

  encrypts :notes

  validates :notes, length: { maximum: 1000 }
end
