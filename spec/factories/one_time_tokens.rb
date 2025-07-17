

# == Schema Information
#
# Table name: one_time_tokens
#
#  cis2_info  :jsonb
#  token      :string           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint
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
FactoryBot.define do
  factory :one_time_token do
    transient { prefix { Faker::Alphanumeric.alpha(number: 2).upcase } }

    user
    token { Faker::Number.hexadecimal(digits: 32) }
  end
end
