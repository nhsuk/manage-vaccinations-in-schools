# frozen_string_literal: true

# == Schema Information
#
# Table name: school_moves
#
#  id            :bigint           not null, primary key
#  academic_year :integer          not null
#  home_educated :boolean
#  source        :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  patient_id    :bigint           not null
#  school_id     :bigint
#  team_id       :bigint
#
# Indexes
#
#  index_school_moves_on_patient_id_and_home_educated_and_team_id  (patient_id,home_educated,team_id) UNIQUE
#  index_school_moves_on_patient_id_and_school_id                  (patient_id,school_id) UNIQUE
#  index_school_moves_on_school_id                                 (school_id)
#  index_school_moves_on_team_id                                   (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (school_id => locations.id)
#  fk_rails_...  (team_id => teams.id)
#
FactoryBot.define do
  factory :school_move do
    patient

    academic_year { AcademicYear.pending }
    source { SchoolMove.sources.keys.sample }

    trait :to_school do
      home_educated { nil }
      team { nil }
      school
    end

    trait :to_home_educated do
      home_educated { true }
      team
      school { nil }
    end

    trait :to_unknown_school do
      home_educated { false }
      team
      school { nil }
    end
  end
end
