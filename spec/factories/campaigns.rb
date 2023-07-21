# == Schema Information
#
# Table name: campaigns
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :campaign do
    name { "HPV" }
    vaccines { [create(:vaccine, type: "HPV")] }

    after :create do |campaign|
      create :session, campaign:
    end
  end
end
