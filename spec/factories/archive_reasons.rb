# frozen_string_literal: true

# == Schema Information
#
# Table name: archive_reasons
#
#  id                 :bigint           not null, primary key
#  other_details      :string           default(""), not null
#  type               :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  created_by_user_id :bigint
#  patient_id         :bigint           not null
#  team_id            :bigint           not null
#
# Indexes
#
#  index_archive_reasons_on_created_by_user_id      (created_by_user_id)
#  index_archive_reasons_on_patient_id              (patient_id)
#  index_archive_reasons_on_team_id                 (team_id)
#  index_archive_reasons_on_team_id_and_patient_id  (team_id,patient_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (created_by_user_id => users.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (team_id => teams.id)
#
FactoryBot.define do
  factory :archive_reason do
    team
    patient

    traits_for_enum :type

    trait :other do
      type { "other" }
      other_details { Faker::Lorem.sentence }
    end
  end
end
