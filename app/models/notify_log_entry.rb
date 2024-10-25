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
class NotifyLogEntry < ApplicationRecord
  self.inheritance_column = nil

  belongs_to :consent_form, optional: true
  belongs_to :patient, optional: true

  enum :type, %i[email sms], validate: true

  validates :template_id, presence: true
  validates :recipient, presence: true

  encrypts :recipient

  def title
    template_name&.to_s&.humanize.presence ||
      "Unknown #{human_enum_name(:type)}"
  end

  private

  def template_name
    if email?
      GOVUK_NOTIFY_EMAIL_TEMPLATES.key(template_id)
    elsif sms?
      GOVUK_NOTIFY_TEXT_TEMPLATES.key(template_id)
    end
  end
end
