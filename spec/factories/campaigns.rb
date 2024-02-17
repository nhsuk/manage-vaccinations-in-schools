# == Schema Information
#
# Table name: campaigns
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  team_id    :integer
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#
FactoryBot.define do
  factory :campaign do
    hpv

    trait :hpv do
      name { "HPV" }
      team
      vaccines { [create(:vaccine, :gardasil_9)] }
    end
  end
end
