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
    transient do
      random { Random.new }
      prefix { ("A".."Z").to_a.sample(2, random:).join }
      days_to_expiry_range { 10..50 }
      days_to_expiry { random.rand(days_to_expiry_range) }
    end

    name { "#{prefix}#{sprintf("%04d", random.rand(10_000))}" }
    expiry { Time.zone.today + days_to_expiry }
    vaccine { create(:vaccine) }
  end
end
