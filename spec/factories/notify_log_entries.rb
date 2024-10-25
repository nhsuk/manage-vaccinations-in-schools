# frozen_string_literal: true

# == Schema Information
#
# Table name: notify_log_entries
#
#  id              :bigint           not null, primary key
#  recipient       :string           not null
#  type            :integer          not null
#  created_at      :datetime         not null
#  consent_form_id :bigint
#  patient_id      :bigint
#  template_id     :string           not null
#
# Indexes
#
#  index_notify_log_entries_on_consent_form_id  (consent_form_id)
#  index_notify_log_entries_on_patient_id       (patient_id)
#
# Foreign Keys
#
#  fk_rails_...  (consent_form_id => consent_forms.id)
#  fk_rails_...  (patient_id => patients.id)
#
FactoryBot.define do
  factory :notify_log_entry do
    patient
    consent_form

    trait :email do
      type { "email" }
      recipient { Faker::Internet.email }
      template_id { GOVUK_NOTIFY_EMAIL_TEMPLATES.values.sample }
    end

    trait :sms do
      type { "sms" }
      recipient { Faker::PhoneNumber.phone_number }
      template_id { GOVUK_NOTIFY_TEXT_TEMPLATES.values.sample }
    end
  end
end
