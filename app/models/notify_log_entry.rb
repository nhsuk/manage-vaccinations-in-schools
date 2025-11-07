# frozen_string_literal: true

# == Schema Information
#
# Table name: notify_log_entries
#
#  id              :bigint           not null, primary key
#  delivery_status :integer          default("sending"), not null
#  programme_ids   :integer          default([]), not null, is an Array
#  programme_types :enum             is an Array
#  recipient       :string           not null
#  type            :integer          not null
#  created_at      :datetime         not null
#  consent_form_id :bigint
#  delivery_id     :uuid
#  parent_id       :bigint
#  patient_id      :bigint
#  sent_by_user_id :bigint
#  template_id     :uuid             not null
#
# Indexes
#
#  index_notify_log_entries_on_consent_form_id  (consent_form_id)
#  index_notify_log_entries_on_delivery_id      (delivery_id)
#  index_notify_log_entries_on_parent_id        (parent_id)
#  index_notify_log_entries_on_patient_id       (patient_id)
#  index_notify_log_entries_on_programme_types  (programme_types) USING gin
#  index_notify_log_entries_on_sent_by_user_id  (sent_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (consent_form_id => consent_forms.id)
#  fk_rails_...  (parent_id => parents.id) ON DELETE => nullify
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (sent_by_user_id => users.id)
#
class NotifyLogEntry < ApplicationRecord
  include Sendable

  self.inheritance_column = nil

  belongs_to :consent_form, optional: true
  belongs_to :patient, optional: true
  belongs_to :parent, optional: true

  enum :type, { email: 0, sms: 1 }, validate: true
  enum :delivery_status,
       {
         sending: 0,
         delivered: 1,
         permanent_failure: 2,
         temporary_failure: 3,
         technical_failure: 4,
         not_uk_mobile_number_failure: 5
       }

  validates :recipient, presence: true
  validates :template_id, presence: true

  encrypts :recipient, deterministic: true

  def title
    template_name&.to_s&.humanize.presence ||
      "Unknown #{human_enum_name(:type)}"
  end

  private

  def template_name
    if GOVUK_NOTIFY_UNUSED_TEMPLATES.include?(template_id)
      GOVUK_NOTIFY_UNUSED_TEMPLATES.fetch(template_id)
    elsif email?
      GOVUK_NOTIFY_EMAIL_TEMPLATES.key(template_id)
    elsif sms?
      GOVUK_NOTIFY_SMS_TEMPLATES.key(template_id)
    end
  end
end
