# == Schema Information
#
# Table name: campaigns
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  vaccine_id :bigint           not null
#
# Indexes
#
#  index_campaigns_on_vaccine_id  (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (vaccine_id => vaccines.id)
#
FactoryBot.define do
  factory :campaign do
    name { "HPV" }
    vaccine { create :vaccine, name: "HPV" }

    after :create do |campaign|
      create :session, campaign:
    end
  end
end
