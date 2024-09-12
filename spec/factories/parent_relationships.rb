# frozen_string_literal: true

# == Schema Information
#
# Table name: parent_relationships
#
#  id         :bigint           not null, primary key
#  other_name :string
#  type       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  parent_id  :bigint           not null
#  patient_id :bigint           not null
#
# Indexes
#
#  index_parent_relationships_on_parent_id                 (parent_id)
#  index_parent_relationships_on_parent_id_and_patient_id  (parent_id,patient_id) UNIQUE
#  index_parent_relationships_on_patient_id                (patient_id)
#
# Foreign Keys
#
#  fk_rails_...  (parent_id => parents.id)
#  fk_rails_...  (patient_id => patients.id)
#
FactoryBot.define do
  factory :parent_relationship do
    patient
    parent { association :parent, :recorded, last_name: patient.last_name }

    type { %w[father guardian mother other].sample }
    other_name { type == "other" ? "Other" : nil }

    traits_for_enum :type

    trait :granddad do
      type { "other" }
      other_name { "Granddad" }
    end
  end
end
