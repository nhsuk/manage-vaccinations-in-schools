# frozen_string_literal: true

FactoryBot.define do
  factory :patient_changeset do
    association :import
    association :school, factory: :school
  end
end
