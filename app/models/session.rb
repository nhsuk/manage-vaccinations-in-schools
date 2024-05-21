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

  DEFAULT_DAYS_FOR_REMINDER = 2

  attr_accessor :reminder_days_after,
                :reminder_days_after_custom,
                :close_consent_on

  delegate :team, to: :campaign
  belongs_to :campaign, optional: true
  belongs_to :location, optional: true
  has_many :consent_forms
  has_many :patient_sessions
  has_many :patients, through: :patient_sessions

  enum :time_of_day, %w[morning afternoon all_day]

  scope :active, -> { where(draft: false) }
  scope :draft, -> { where(draft: true) }
  scope :past, -> { where(date: ..Time.zone.yesterday) }
  scope :in_progress, -> { where(date: Time.zone.today) }
  scope :future, -> { where(date: Time.zone.tomorrow..) }

  default_scope { active }

  delegate :name, to: :location

  after_initialize :set_timeline_attributes
  after_validation :set_timeline_timestamps

  on_wizard_step :location, exact: true do
    validates :location_id,
              presence: true,
              inclusion: {
                in: ->(object) { object.team.locations.pluck(:id) }
              }
  end

  on_wizard_step :when, exact: true do
    validates :date, presence: true

    validates :time_of_day,
              presence: true,
              inclusion: {
                in: Session.time_of_days.keys
              }
  end

  on_wizard_step :cohort, exact: true do
    validates :patients, presence: true
  end

  on_wizard_step :timeline, exact: true do
    validates :send_consent_at,
              presence: true,
              comparison: {
                greater_than_or_equal_to: -> { Time.zone.today },
                less_than_or_equal_to: ->(object) { object.date }
              }

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
    %i[location when cohort timeline confirm]
  end

  def days_between_consent_and_session
    (date - send_consent_at).to_i
  end

  def days_between_consent_and_reminder
    (send_reminders_at - send_consent_at).to_i
  end

  def unmatched_consent_forms
    consent_forms.unmatched.recorded.order(:recorded_at)
  end

  private

  def set_timeline_attributes
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
    return if errors.any? || reminder_days_after.nil?

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

    self.send_reminders_at = send_consent_at + reminder_days_after.days
    self.close_consent_at = close_consent_on
  end
end
