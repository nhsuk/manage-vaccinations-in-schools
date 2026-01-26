# frozen_string_literal: true

# == Schema Information
#
# Table name: notify_log_entries
#
#  id              :bigint           not null, primary key
#  delivery_status :integer          default("sending"), not null
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

  has_one :team_location, through: :consent_form

  has_many :notify_log_entry_programmes,
           class_name: "NotifyLogEntry::Programme",
           inverse_of: :notify_log_entry,
           dependent: :destroy

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

  scope :for_programme_type,
        ->(programme_type) do
          where(
            NotifyLogEntry::Programme
              .select("1")
              .where("notify_log_entry_id = notify_log_entries.id")
              .where(programme_type:)
              .arel
              .exists
          )
        end

  scope :for_session,
        ->(session) do
          where(
            NotifyLogEntry::Programme
              .select("1")
              .where("notify_log_entry_id = notify_log_entries.id")
              .where(programme_type: session.programme_types)
              .group(:notify_log_entry_id)
              .having(
                "COUNT(DISTINCT programme_type) = ?",
                session.programme_types.count
              )
              .arel
              .exists
          )
        end

  encrypts :recipient, deterministic: true

  accepts_nested_attributes_for :notify_log_entry_programmes

  def title
    template_name&.to_s&.humanize.presence ||
      "Unknown #{human_enum_name(:type)}"
  end

  def programmes = notify_log_entry_programmes.map(&:programme)

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
