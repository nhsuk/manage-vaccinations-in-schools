# frozen_string_literal: true

# == Schema Information
#
# Table name: pre_screenings
#
#  id                   :bigint           not null, primary key
#  feeling_well         :boolean          not null
#  knows_vaccination    :boolean          not null
#  no_allergies         :boolean          not null
#  not_already_had      :boolean          not null
#  notes                :text             default(""), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  patient_session_id   :bigint           not null
#  performed_by_user_id :bigint           not null
#
# Indexes
#
#  index_pre_screenings_on_patient_session_id    (patient_session_id)
#  index_pre_screenings_on_performed_by_user_id  (performed_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_session_id => patient_sessions.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#
class PreScreening < ApplicationRecord
  audited

  belongs_to :patient_session
  belongs_to :performed_by,
             class_name: "User",
             foreign_key: :performed_by_user_id

  encrypts :notes

  validates :knows_vaccination,
            :not_already_had,
            :feeling_well,
            :no_allergies,
            inclusion: {
              in: [true, false]
            }

  def allows_vaccination?
    knows_vaccination && not_already_had && no_allergies
  end
end
