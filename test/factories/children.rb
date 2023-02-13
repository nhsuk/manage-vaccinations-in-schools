FactoryBot.define do
  factory :child do
    nhs_number { rand(10**10) }
    sex { %w[Male Female].sample }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    gp { "Local GP" }
    screening { "Approved for vaccination" }
    consent { "Parental consent (digital)" }
    seen { "Not yet" }
    dob { rand(3..9).years.ago }
  end
end
