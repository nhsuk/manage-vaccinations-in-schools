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
