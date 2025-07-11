

FactoryBot.define do
  factory :one_time_token do
    transient { prefix { Faker::Alphanumeric.alpha(number: 2).upcase } }

    user
    token { Faker::Number.hexadecimal(digits: 32) }
  end
end