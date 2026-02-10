# frozen_string_literal: true

# == Schema Information
#
# Table name: gillick_assessments
#
#  id                   :bigint           not null, primary key
#  date                 :date             not null
#  knows_consequences   :boolean          not null
#  knows_delivery       :boolean          not null
#  knows_disease        :boolean          not null
#  knows_side_effects   :boolean          not null
#  knows_vaccination    :boolean          not null
#  notes                :text             default(""), not null
#  programme_type       :enum             not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  location_id          :bigint           not null
#  patient_id           :bigint           not null
#  performed_by_user_id :bigint           not null
#
# Indexes
#
#  index_gillick_assessments_on_location_id           (location_id)
#  index_gillick_assessments_on_patient_id            (patient_id)
#  index_gillick_assessments_on_performed_by_user_id  (performed_by_user_id)
#  index_gillick_assessments_on_programme_type        (programme_type)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#
class GillickAssessment < ApplicationRecord
  include BelongsToLocationAndDate
  include BelongsToPerformedByUser
  include BelongsToProgramme
  include Notable

  audited associated_with: :patient

  belongs_to :patient

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
