# frozen_string_literal: true

# == Schema Information
#
# Table name: one_time_tokens
#
#  cis2_info  :jsonb
#  jsonb      :jsonb
#  token      :string           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_one_time_tokens_on_created_at  (created_at)
#  index_one_time_tokens_on_token       (token) UNIQUE
#  index_one_time_tokens_on_user_id     (user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
#
class Reporting::OneTimeToken < ApplicationRecord
  self.table_name = "one_time_tokens"

  belongs_to :user

  validates :user_id, uniqueness: true
  validates :token, uniqueness: true

  def self.generate!(user_id:, cis2_info: {})
    create!(user_id: user_id, token: SecureRandom.hex(32), cis2_info: cis2_info)
  end

  def self.expire_before
    Settings.reporting_api.client_app.token_ttl_seconds.seconds.ago
  end

  def self.find_or_generate_for!(user:, cis2_info: {})
    transaction do
      token = find_by(user_id: user.id)
      token.delete if token&.expired?

      token || generate!(user_id: user.id, cis2_info:)
    end
  end

  def expired?
    created_at < self.class.expire_before
  end
end
