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
FactoryBot.define do
  factory :patient_specific_direction do
    created_by
    patient
    programme
    vaccine

    delivery_site { "left_arm_upper_position" }
    vaccine_method { "injection" }
    full_dose { true }

    trait :half_dose do
      full_dose { false }
    end
  end
end
