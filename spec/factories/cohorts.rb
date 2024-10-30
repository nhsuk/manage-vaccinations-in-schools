# frozen_string_literal: true

# == Schema Information
#
# Table name: cohorts
#
#  id                  :bigint           not null, primary key
#  birth_academic_year :integer          not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  organisation_id     :bigint           not null
#
# Indexes
#
#  index_cohorts_on_organisation_id                          (organisation_id)
#  index_cohorts_on_organisation_id_and_birth_academic_year  (organisation_id,birth_academic_year) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#
FactoryBot.define do
  factory :cohort do
    team
    birth_academic_year { Time.zone.today.year - 10 }
  end
end
