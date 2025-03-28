# frozen_string_literal: true

# == Schema Information
#
# Table name: school_moves
#
#  id              :bigint           not null, primary key
#  home_educated   :boolean
#  source          :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organisation_id :bigint
#  patient_id      :bigint           not null
#  school_id       :bigint
#
# Indexes
#
#  idx_on_patient_id_home_educated_organisation_id_7c1b5f5066  (patient_id,home_educated,organisation_id) UNIQUE
#  index_school_moves_on_organisation_id                       (organisation_id)
#  index_school_moves_on_patient_id_and_school_id              (patient_id,school_id) UNIQUE
#  index_school_moves_on_school_id                             (school_id)
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (school_id => locations.id)
#
FactoryBot.define do
  factory :school_move do
    patient

    source { SchoolMove.sources.keys.sample }

    trait :to_school do
      home_educated { nil }
      organisation { nil }
      school
    end

    trait :to_home_educated do
      home_educated { true }
      organisation
      school { nil }
    end

    trait :to_unknown_school do
      home_educated { false }
      organisation
      school { nil }
    end
  end
end
