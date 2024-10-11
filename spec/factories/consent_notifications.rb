# frozen_string_literal: true

# == Schema Information
#
# Table name: consent_notifications
#
#  id           :bigint           not null, primary key
#  reminder     :boolean          not null
#  sent_at      :datetime         not null
#  patient_id   :bigint           not null
#  programme_id :bigint           not null
#
# Indexes
#
#  index_consent_notifications_on_patient_id                   (patient_id)
#  index_consent_notifications_on_patient_id_and_programme_id  (patient_id,programme_id)
#  index_consent_notifications_on_programme_id                 (programme_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (programme_id => programmes.id)
#
FactoryBot.define do
  factory :consent_notification do
    patient
    programme

    reminder { [true, false].sample }

    trait :request do
      reminder { false }
    end

    trait :reminder do
      reminder { true }
    end
  end
end
