# frozen_string_literal: true

# == Schema Information
#
# Table name: triage
#
#  id                   :bigint           not null, primary key
#  invalidated_at       :datetime
#  notes                :text             default(""), not null
#  status               :integer          not null
#  vaccine_method       :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  organisation_id      :bigint           not null
#  patient_id           :bigint           not null
#  performed_by_user_id :bigint           not null
#  programme_id         :bigint           not null
#
# Indexes
#
#  index_triage_on_organisation_id       (organisation_id)
#  index_triage_on_patient_id            (patient_id)
#  index_triage_on_performed_by_user_id  (performed_by_user_id)
#  index_triage_on_programme_id          (programme_id)
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#  fk_rails_...  (programme_id => programmes.id)
#
FactoryBot.define do
  factory :triage do
    patient
    performed_by
    programme

    organisation { performed_by.organisations.first }

    notes { "" }

    # TODO: Remove this default and require users of this factory to be
    #  explicit about the status they want.
    status { "ready_to_vaccinate" }
    vaccine_method { "injection" }

    traits_for_enum :status
    traits_for_enum :vaccine_method

    trait :ready_to_vaccinate do
      status { "ready_to_vaccinate" }
      vaccine_method { "injection" }
    end

    trait :invalidated do
      invalidated_at { Time.current }
    end
  end
end
