# == Schema Information
#
# Table name: patients
#
#  id             :bigint           not null, primary key
#  consent        :integer
#  dob            :date
#  first_name     :text
#  last_name      :text
#  nhs_number     :bigint
#  preferred_name :text
#  screening      :integer
#  seen           :integer
#  sex            :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_patients_on_nhs_number  (nhs_number) UNIQUE
#
FactoryBot.define do
  factory :patient do
    nhs_number { rand(10**10) }
    sex { %w[Male Female].sample }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    screening { "Approved for vaccination" }
    consent { "Parental consent (digital)" }
    seen { "Not yet" }
    dob { rand(3..9).years.ago }
  end
end
