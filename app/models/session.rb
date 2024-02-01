# == Schema Information
#
# Table name: sessions
#
#  id                :bigint           not null, primary key
#  close_consent_at  :date
#  date              :date
#  draft             :boolean          default(FALSE)
#  send_consent_at   :date
#  send_reminders_at :date
#  time_of_day       :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  campaign_id       :bigint
#  location_id       :bigint
#
# Indexes
#
#  index_sessions_on_campaign_id  (campaign_id)
#
class Session < ApplicationRecord
  include WizardFormConcern
  audited

  DEFAULT_DAYS_FOR_CONSENT = 14
  DEFAULT_DAYS_FOR_REMINDER = 7

  attr_accessor :consent_days_before,
                :consent_days_before_custom,
                :reminder_days_after,
                :reminder_days_after_custom,
                :close_consent_on,
                :team

  belongs_to :campaign, optional: true
  belongs_to :location, optional: true
  has_many :consent_forms
  has_many :patient_sessions
  has_many :patients, through: :patient_sessions

  enum :time_of_day, %w[morning afternoon all_day]

  scope :active, -> { where(draft: false) }
  scope :draft, -> { where(draft: true) }

  delegate :name, to: :location

  after_initialize :set_timeline_attributes
  after_validation :set_timeline_timestamps

  on_wizard_step :location, exact: true do
    validates :location_id,
              presence: true,
              inclusion: {
                in: ->(object) do
                  # Location must exist in campaign this session is attached to.
                  # If there is no campaign yet (during creation), use the
                  # current user's team instead, which is passed in as
                  # object.team
                  (object.campaign&.team || object.team).locations.pluck(:id)
                end
              }
  end

  on_wizard_step :vaccine, exact: true do
    validates :campaign_id,
              presence: true,
              inclusion: {
                in: ->(object) { object.team.campaigns.pluck :id }
              }
  end

  on_wizard_step :when, exact: true do
    validates :date,
              presence: true,
              comparison: {
                greater_than_or_equal_to:
                  Date.parse(Settings.pilot.earliest_session_date),
                less_than_or_equal_to:
                  Date.parse(Settings.pilot.latest_session_date)
              }

    validates :time_of_day,
              presence: true,
              inclusion: {
                in: Session.time_of_days.keys
              }
  end

  on_wizard_step :timeline, exact: true do
    validates :consent_days_before,
              presence: true,
              inclusion: {
                in: %w[default custom]
              }
    validates :consent_days_before_custom,
              presence: true,
              numericality: {
                greater_than_or_equal_to: 10,
                less_than_or_equal_to: 30
              },
              if: -> { consent_days_before == "custom" }

    validates :reminder_days_after,
              presence: true,
              inclusion: {
                in: %w[default custom]
              }
    validates :reminder_days_after_custom,
              presence: true,
              numericality: {
                greater_than_or_equal_to: 2,
                less_than_or_equal_to: 7
              },
              if: -> { reminder_days_after == "custom" }

    validates :close_consent_on,
              presence: true,
              inclusion: {
                in: %w[default custom]
              }
    validates :close_consent_at,
              presence: true,
              if: -> { close_consent_on == "custom" }
  end

  def health_questions
    campaign.vaccines.first.health_questions
  end

  def type
    campaign.name
  end

  def in_progress?
    date.to_date == Time.zone.today
  end

  def form_steps
    %i[location vaccine when timeline confirm]
  end

  def days_between_consent_and_session
    (date - send_consent_at).to_i
  end

  def days_between_consent_and_reminder
    (send_reminders_at - send_consent_at).to_i
  end

  private

  def set_timeline_attributes
    unless send_consent_at.nil?
      if date - DEFAULT_DAYS_FOR_CONSENT.days == send_consent_at
        self.consent_days_before = "default"
      else
        self.consent_days_before = "custom"
        self.consent_days_before_custom = days_between_consent_and_session
      end
    end

    unless send_reminders_at.nil?
      if send_consent_at + DEFAULT_DAYS_FOR_REMINDER.days == send_reminders_at
        self.reminder_days_after = "default"
      else
        self.reminder_days_after = "custom"
        self.reminder_days_after_custom = days_between_consent_and_reminder
      end
    end

    unless close_consent_at.nil?
      self.close_consent_on = close_consent_at == date ? "default" : "custom"
    end
  end

  def set_timeline_timestamps
    return if errors.any? || consent_days_before.nil?

    consent_days_before =
      (
        if self.consent_days_before == "default"
          DEFAULT_DAYS_FOR_CONSENT
        else
          consent_days_before_custom.to_i
        end
      )
    reminder_days_after =
      (
        if self.reminder_days_after == "default"
          DEFAULT_DAYS_FOR_REMINDER
        else
          reminder_days_after_custom.to_i
        end
      )
    close_consent_on =
      self.close_consent_on == "default" ? date : close_consent_at

    self.send_consent_at = date - consent_days_before.days
    self.send_reminders_at = send_consent_at + reminder_days_after.days
    self.close_consent_at = close_consent_on
  end
end
