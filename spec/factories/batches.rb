# frozen_string_literal: true

# == Schema Information
#
# Table name: batches
#
#  id         :bigint           not null, primary key
#  expiry     :date             not null
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  vaccine_id :bigint           not null
#
# Indexes
#
#  index_batches_on_vaccine_id  (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (vaccine_id => vaccines.id)
#

FactoryBot.define do
  factory :batch do
    transient { prefix { Faker::Alphanumeric.alpha(number: 2).upcase } }

    name { "#{prefix}#{Faker::Number.number(digits: 4)}" }
    expiry { Faker::Time.forward(days: 50) }
    vaccine
  end
end
