# frozen_string_literal: true

# == Schema Information
#
# Table name: batches
#
#  id              :bigint           not null, primary key
#  archived_at     :datetime
#  expiry          :date             not null
#  name            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organisation_id :bigint           not null
#  vaccine_id      :bigint           not null
#
# Indexes
#
#  idx_on_organisation_id_name_expiry_vaccine_id_6d9ae30338  (organisation_id,name,expiry,vaccine_id) UNIQUE
#  index_batches_on_organisation_id                          (organisation_id)
#  index_batches_on_vaccine_id                               (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#  fk_rails_...  (vaccine_id => vaccines.id)
#

FactoryBot.define do
  factory :batch do
    transient { prefix { Faker::Alphanumeric.alpha(number: 2).upcase } }

    organisation
    vaccine

    name { "#{prefix}#{Faker::Number.number(digits: 4)}" }
    expiry { Faker::Time.forward(days: 50) }

    trait :expired do
      expiry { Date.yesterday }
    end

    trait :archived do
      archived_at { Time.current }
    end
  end
end
