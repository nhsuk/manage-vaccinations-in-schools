# == Schema Information
#
# Table name: campaigns
#
#  id            :bigint           not null, primary key
#  date          :datetime
#  location_type :text
#  type          :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  location_id   :integer
#
FactoryBot.define do
  factory :campaign do
    date { Time.zone.today }
    type { "HPV" }
    location_type { nil }
    location { create(:school) }

    after :create do |campaign|
      create_list :child, 100, campaigns: [campaign]
    end
  end
end
