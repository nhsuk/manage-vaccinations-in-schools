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
    team
    hpv

    trait :hpv do
      name { "HPV" }
      vaccines { [create(:vaccine, :gardasil_9)] }
    end

    trait :flu do
      name { "Flu" }
      vaccines do
        [create(:vaccine, :fluenz_tetra), create(:vaccine, :fluerix_tetra)]
      end
    end

    trait :flu_nasal_only do
      name { "Flu" }
      vaccines { [create(:vaccine, :fluenz_tetra)] }
    end
  end
end
