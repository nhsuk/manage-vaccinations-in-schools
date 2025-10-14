# frozen_string_literal: true

# == Schema Information
#
# Table name: triage
#
#  id                   :bigint           not null, primary key
#  academic_year        :integer          not null
#  invalidated_at       :datetime
#  notes                :text             default(""), not null
#  status               :integer          not null
#  vaccine_method       :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  patient_id           :bigint           not null
#  performed_by_user_id :bigint           not null
#  programme_id         :bigint           not null
#  team_id              :bigint           not null
#
# Indexes
#
#  index_triage_on_academic_year         (academic_year)
#  index_triage_on_patient_id            (patient_id)
#  index_triage_on_performed_by_user_id  (performed_by_user_id)
#  index_triage_on_programme_id          (programme_id)
#  index_triage_on_team_id               (team_id)
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
    performed_by
    programme

    team { performed_by.teams.first }

    notes { "" }

    # TODO: Remove this default and require users of this factory to be
    #  explicit about the status they want.
    status { "safe_to_vaccinate" }
    vaccine_method { "injection" }

    academic_year do
      created_at&.to_date&.academic_year || Time.current.to_date.academic_year
    end

    traits_for_enum :status
    traits_for_enum :vaccine_method

    trait :safe_to_vaccinate do
      status { "safe_to_vaccinate" }
      vaccine_method { "injection" }
    end

    trait :nasal_only do
      vaccine_method { "nasal" }
    end

    trait :do_not_vaccinate do
      status { "do_not_vaccinate" }
      vaccine_method { nil }
    end

    trait :keep_in_triage do
      status { "keep_in_triage" }
      vaccine_method { nil }
    end

    trait :delay_vaccination do
      status { "delay_vaccination" }
      vaccine_method { nil }
    end

    trait :invalidated do
      invalidated_at { Time.current }
    end
  end
end
