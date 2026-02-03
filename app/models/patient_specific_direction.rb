# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_specific_directions
#
#  id                 :bigint           not null, primary key
#  academic_year      :integer          not null
#  delivery_site      :integer          not null
#  invalidated_at     :datetime
#  programme_type     :enum             not null
#  vaccine_method     :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  created_by_user_id :bigint           not null
#  patient_id         :bigint           not null
#  team_id            :bigint           not null
#  vaccine_id         :bigint           not null
#
# Indexes
#
#  index_patient_specific_directions_on_academic_year       (academic_year)
#  index_patient_specific_directions_on_created_by_user_id  (created_by_user_id)
#  index_patient_specific_directions_on_patient_id          (patient_id)
#  index_patient_specific_directions_on_programme_type      (programme_type)
#  index_patient_specific_directions_on_team_id             (team_id)
#  index_patient_specific_directions_on_vaccine_id          (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_user_id => users.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (team_id => teams.id)
#  fk_rails_...  (vaccine_id => vaccines.id)
#
class PatientSpecificDirection < ApplicationRecord
  include BelongsToProgramme
  include Invalidatable

  audited associated_with: :patient

  belongs_to :created_by, class_name: "User", foreign_key: :created_by_user_id
  belongs_to :patient
  belongs_to :team
  belongs_to :vaccine

  enum :delivery_site,
       {
         left_arm_upper_position: 2,
         left_arm_lower_position: 3,
         right_arm_upper_position: 4,
         right_arm_lower_position: 5,
         left_thigh: 6,
         right_thigh: 7,
         left_buttock: 8,
         right_buttock: 9,
         nose: 10
       },
       validate: true

  enum :vaccine_method, { injection: 0, nasal: 1 }, prefix: true, validate: true

  scope :for_session,
        ->(session) { where(programme_type: session.programme_types) }
end
