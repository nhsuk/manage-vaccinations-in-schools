# == Schema Information
#
# Table name: vaccines
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_vaccines_on_name  (name) UNIQUE
#
FactoryBot.define do
  factory :vaccine do
    initialize_with { Vaccine.find_or_initialize_by(name:) }

    name { "HPV" }
  end
end
