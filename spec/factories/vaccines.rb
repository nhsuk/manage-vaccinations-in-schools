# == Schema Information
#
# Table name: vaccines
#
#  id         :bigint           not null, primary key
#  brand      :text
#  method     :integer
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_vaccines_on_type  (type) UNIQUE
#
FactoryBot.define do
  factory :vaccine do
    initialize_with { Vaccine.find_or_initialize_by(type:) }

    type { "HPV" }
    brand { "Gardasil 9" }
    add_attribute(:method) { :injection }
  end
end
