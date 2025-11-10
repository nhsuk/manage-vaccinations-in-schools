# frozen_string_literal: true

# == Schema Information
#
# Table name: triages
#
#  id                      :bigint           not null, primary key
#  academic_year           :integer          not null
#  delay_vaccination_until :date
#  invalidated_at          :datetime
#  notes                   :text             default(""), not null
#  programme_type          :enum             not null
#  status                  :integer          not null
#  vaccine_method          :integer
#  without_gelatine        :boolean
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  patient_id              :bigint           not null
#  performed_by_user_id    :bigint           not null
#  programme_id            :bigint
#  team_id                 :bigint           not null
#
# Indexes
#
#  index_triages_on_academic_year         (academic_year)
#  index_triages_on_patient_id            (patient_id)
#  index_triages_on_performed_by_user_id  (performed_by_user_id)
#  index_triages_on_programme_type        (programme_type)
#  index_triages_on_team_id               (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (team_id => teams.id)
#
FactoryBot.define do
  factory :triage do
    patient
    programme { CachedProgramme.sample }

    performed_by
    team { performed_by.teams.first }

    notes { "" }

    academic_year { created_at&.to_date&.academic_year || AcademicYear.current }

    traits_for_enum :status
    traits_for_enum :vaccine_method

    trait :safe_to_vaccinate do
      status { "safe_to_vaccinate" }
      injection
      without_gelatine { false }
    end

    trait :safe_to_vaccinate_nasal do
      status { "safe_to_vaccinate" }
      nasal
      without_gelatine { false }
    end

    trait :safe_to_vaccinate_without_gelatine do
      safe_to_vaccinate
      without_gelatine
    end

    trait :without_gelatine do
      without_gelatine { true }
    end

    trait :invalidated do
      invalidated_at { Time.current }
    end

    trait :delay_vaccination do
      status { "delay_vaccination" }
    end

    trait :expired do
      delay_vaccination_until { Date.yesterday }
    end
  end
end
