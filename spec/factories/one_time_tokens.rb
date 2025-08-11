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
FactoryBot.define do
  factory :reporting_api_one_time_token, class: ReportingAPI::OneTimeToken do
    transient { prefix { Faker::Alphanumeric.alpha(number: 2).upcase } }

    user
    token { Faker::Number.hexadecimal(digits: 32) }
  end
end
