# frozen_string_literal: true

# == Schema Information
#
# Table name: gillick_assessments
#
#  id                   :bigint           not null, primary key
#  knows_consequences   :boolean          not null
#  knows_delivery       :boolean          not null
#  knows_disease        :boolean          not null
#  knows_side_effects   :boolean          not null
#  knows_vaccination    :boolean          not null
#  notes                :text             default(""), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  patient_session_id   :bigint           not null
#  performed_by_user_id :bigint           not null
#
# Indexes
#
#  index_gillick_assessments_on_patient_session_id    (patient_session_id) UNIQUE
#  index_gillick_assessments_on_performed_by_user_id  (performed_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_session_id => patient_sessions.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#
class GillickAssessment < ApplicationRecord
  audited

  belongs_to :patient_session
  belongs_to :performed_by,
             class_name: "User",
             foreign_key: :performed_by_user_id

  has_one :patient, through: :patient_session
  has_one :session, through: :patient_session
  has_one :location, through: :session

  encrypts :notes

  validates :knows_consequences,
            :knows_delivery,
            :knows_disease,
            :knows_side_effects,
            :knows_vaccination,
            inclusion: {
              in: [true, false]
            }

  def gillick_competent?
    knows_consequences && knows_delivery && knows_disease &&
      knows_side_effects && knows_vaccination
  end
end
