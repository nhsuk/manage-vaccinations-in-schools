# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                  :bigint           not null, primary key
#  current_sign_in_at  :datetime
#  current_sign_in_ip  :string
#  email               :string
#  encrypted_password  :string           default(""), not null
#  family_name         :string           not null
#  given_name          :string           not null
#  last_sign_in_at     :datetime
#  last_sign_in_ip     :string
#  provider            :string
#  remember_created_at :datetime
#  sign_in_count       :integer          default(0), not null
#  uid                 :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_users_on_email             (email) UNIQUE
#  index_users_on_provider_and_uid  (provider,uid) UNIQUE
#

describe User do
  subject(:user) { build(:user) }

  describe "validations" do
    it { should validate_presence_of(:given_name) }
    it { should validate_presence_of(:family_name) }
    it { should validate_length_of(:given_name).is_at_most(255) }
    it { should validate_length_of(:family_name).is_at_most(255) }
  end
end
