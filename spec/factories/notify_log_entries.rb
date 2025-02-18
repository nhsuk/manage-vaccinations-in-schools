# frozen_string_literal: true

# == Schema Information
#
# Table name: notify_log_entries
#
#  id                      :bigint           not null, primary key
#  delivery_status         :integer          default("sending"), not null
#  recipient               :string
#  recipient_deterministic :string
#  type                    :integer          not null
#  created_at              :datetime         not null
#  consent_form_id         :bigint
#  delivery_id             :uuid
#  parent_id               :bigint
#  patient_id              :bigint
#  sent_by_user_id         :bigint
#  template_id             :uuid             not null
#
# Indexes
#
#  index_notify_log_entries_on_consent_form_id  (consent_form_id)
#  index_notify_log_entries_on_delivery_id      (delivery_id)
#  index_notify_log_entries_on_parent_id        (parent_id)
#  index_notify_log_entries_on_patient_id       (patient_id)
#  index_notify_log_entries_on_sent_by_user_id  (sent_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (consent_form_id => consent_forms.id)
#  fk_rails_...  (parent_id => parents.id) ON DELETE => nullify
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (sent_by_user_id => users.id)
#
FactoryBot.define do
  factory :notify_log_entry do
    patient

    trait :email do
      type { "email" }
      recipient { Faker::Internet.email }
      template_id { GOVUK_NOTIFY_EMAIL_TEMPLATES.values.sample }
    end

    trait :sms do
      type { "sms" }
      recipient { Faker::PhoneNumber.phone_number }
      template_id { GOVUK_NOTIFY_SMS_TEMPLATES.values.sample }
    end

    recipient_deterministic { recipient }

    delivery_id { SecureRandom.uuid }
    traits_for_enum :delivery_status
  end
end
