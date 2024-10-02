# frozen_string_literal: true

# == Schema Information
#
# Table name: teams
#
#  id                                              :bigint           not null, primary key
#  days_before_first_consent_reminder              :integer          default(7), not null
#  days_between_consent_reminders                  :integer          default(7), not null
#  days_between_first_session_and_consent_requests :integer          default(21), not null
#  email                                           :string
#  maximum_number_of_consent_reminders             :integer          default(4), not null
#  name                                            :text             not null
#  ods_code                                        :string           not null
#  phone                                           :string
#  privacy_policy_url                              :string
#  send_updates_by_text                            :boolean          default(FALSE), not null
#  created_at                                      :datetime         not null
#  updated_at                                      :datetime         not null
#  reply_to_id                                     :uuid
#
# Indexes
#
#  index_teams_on_name      (name) UNIQUE
#  index_teams_on_ods_code  (ods_code) UNIQUE
#

describe Team do
  subject(:team) { build(:team) }

  describe "validations" do
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:ods_code) }
    it { should validate_presence_of(:phone) }

    it { should validate_uniqueness_of(:name) }
    it { should validate_uniqueness_of(:ods_code) }
  end
end
