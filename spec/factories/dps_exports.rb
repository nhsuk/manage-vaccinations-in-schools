# frozen_string_literal: true

# == Schema Information
#
# Table name: dps_exports
#
#  id           :bigint           not null, primary key
#  filename     :string           not null
#  sent_at      :datetime
#  status       :string           default("pending"), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  message_id   :string
#  programme_id :bigint           not null
#
# Indexes
#
#  index_dps_exports_on_programme_id  (programme_id)
#
# Foreign Keys
#
#  fk_rails_...  (programme_id => programmes.id)
#
FactoryBot.define do
  factory :dps_export do
    programme { association :programme, :active }
    sequence(:filename) { |n| "dps_export_#{n}.csv" }
    status { "pending" }

    trait :with_message_id do
      sequence(:message_id, &:to_s)
    end

    trait :accepted do
      with_message_id
      status { "accepted" }
    end

    trait :acknowledged do
      with_message_id
      status { "acknowledged" }
    end
  end
end
