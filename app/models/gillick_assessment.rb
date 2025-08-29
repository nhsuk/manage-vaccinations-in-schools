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
#  patient_id           :bigint           not null
#  performed_by_user_id :bigint           not null
#  programme_id         :bigint           not null
#  session_date_id      :bigint           not null
#
# Indexes
#
#  index_gillick_assessments_on_patient_id            (patient_id)
#  index_gillick_assessments_on_performed_by_user_id  (performed_by_user_id)
#  index_gillick_assessments_on_programme_id          (programme_id)
#  index_gillick_assessments_on_session_date_id       (session_date_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (session_date_id => session_dates.id)
#
class GillickAssessment < ApplicationRecord
  audited associated_with: :patient

  belongs_to :patient
  belongs_to :session_date
  belongs_to :programme

  belongs_to :performed_by,
             class_name: "User",
             foreign_key: :performed_by_user_id

  has_one :session, through: :session_date

  delegate :academic_year, to: :session

  encrypts :notes

  validates :knows_consequences,
            :knows_delivery,
            :knows_disease,
            :knows_side_effects,
            :knows_vaccination,
            inclusion: {
              in: [true, false]
            }

  validates :notes, length: { maximum: 1000 }

  def gillick_competent?
    knows_consequences && knows_delivery && knows_disease &&
      knows_side_effects && knows_vaccination
  end
end
