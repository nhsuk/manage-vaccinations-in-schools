# frozen_string_literal: true

# == Schema Information
#
# Table name: reporting_api_one_time_tokens
#
#  cis2_info  :jsonb            not null
#  token      :string           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_reporting_api_one_time_tokens_on_created_at  (created_at)
#  index_reporting_api_one_time_tokens_on_token       (token) UNIQUE
#  index_reporting_api_one_time_tokens_on_user_id     (user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class ReportingAPI::OneTimeToken < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true, presence: true
  validates :token, uniqueness: true, presence: true

  JWT_SIGNING_ALGORITHM = "HS512"

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

      token&.persisted? ? token : generate!(user_id: user.id, cis2_info:)
    end
  end

  def expired?
    created_at < self.class.expire_before
  end

  def jwt_payload
    {
      "iat" => Time.current.utc.to_i,
      "data" => {
        "user" => user.as_json,
        "cis2_info" => cis2_info
      }
    }
  end

  def to_jwt
    JWT.encode(
      jwt_payload,
      Settings.reporting_api.client_app.secret,
      JWT_SIGNING_ALGORITHM
    )
  end
end
