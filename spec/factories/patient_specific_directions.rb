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
#  programme_id       :bigint           not null
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
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (team_id => teams.id)
#  fk_rails_...  (vaccine_id => vaccines.id)
#
FactoryBot.define do
  factory :patient_specific_direction do
    created_by { association(:user, :prescriber) }
    patient
    programme { CachedProgramme.sample }
    team
    vaccine { programme.vaccines.sample || association(:vaccine) }

    delivery_site { "nose" }
    vaccine_method { "nasal" }
    academic_year { AcademicYear.current }

    trait :invalidated do
      invalidated_at { Time.current }
    end
  end
end
