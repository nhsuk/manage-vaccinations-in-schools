# == Schema Information
#
# Table name: sessions
#
#  id          :bigint           not null, primary key
#  date        :datetime
#  name        :text             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  campaign_id :bigint           not null
#  location_id :bigint
#
# Indexes
#
#  index_sessions_on_campaign_id  (campaign_id)
#
FactoryBot.define do
  factory :session do
    transient { patients_in_session { 100 } }

    campaign { create :campaign }
    location

    date { Time.zone.today }
    name { "#{campaign.name} session at #{location.name}" }

    after :create do |session, context|
      create_list :patient, context.patients_in_session, sessions: [session]
    end
  end
end
