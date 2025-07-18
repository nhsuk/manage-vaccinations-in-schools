# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_specific_directions
#
#  id                 :bigint           not null, primary key
#  delivery_site      :integer          not null
#  full_dose          :boolean          not null
#  vaccine_method     :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  created_by_user_id :bigint           not null
#  patient_id         :bigint           not null
#  programme_id       :bigint           not null
#  vaccine_id         :bigint           not null
#
# Indexes
#
#  index_patient_specific_directions_on_created_by_user_id  (created_by_user_id)
#  index_patient_specific_directions_on_patient_id          (patient_id)
#  index_patient_specific_directions_on_programme_id        (programme_id)
#  index_patient_specific_directions_on_vaccine_id          (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_user_id => users.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (vaccine_id => vaccines.id)
#
class PatientSpecificDirection < ApplicationRecord
  audited associated_with: :patient

  belongs_to :created_by, class_name: "User", foreign_key: :created_by_user_id
  belongs_to :patient
  belongs_to :programme
  belongs_to :vaccine

  validates :full_dose, inclusion: { in: [true, false] }

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
end
