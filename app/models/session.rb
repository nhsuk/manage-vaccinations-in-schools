# frozen_string_literal: true

# == Schema Information
#
# Table name: sessions
#
#  id                        :bigint           not null, primary key
#  active                    :boolean          default(FALSE), not null
#  close_consent_at          :date
#  date                      :date
#  send_consent_reminders_at :date
#  send_consent_requests_at  :date
#  time_of_day               :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  location_id               :bigint
#  programme_id              :bigint
#  team_id                   :bigint           not null
#
# Indexes
#
#  index_sessions_on_programme_id  (programme_id)
#  index_sessions_on_team_id       (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (team_id => teams.id)
#
class Session < ApplicationRecord
  include Draftable
  include WizardStepConcern

  audited

  DEFAULT_DAYS_FOR_REMINDER = 2

  attr_accessor :reminder_days_after,
                :reminder_days_after_custom,
                :close_consent_on

  belongs_to :team
  belongs_to :programme, optional: true
  belongs_to :location, optional: true

  has_many :consent_forms
  has_many :patient_sessions
  has_many :patients, through: :patient_sessions

  has_and_belongs_to_many :immunisation_imports

  enum :time_of_day, %w[morning afternoon all_day], validate: { if: :active? }

  scope :past, -> { where(date: ..Time.zone.yesterday) }
  scope :in_progress, -> { where(date: Time.zone.today) }
  scope :future, -> { where(date: Time.zone.tomorrow..) }
  scope :tomorrow, -> { where(date: Time.zone.tomorrow) }

  scope :send_consent_requests_today,
        -> { active.where(send_consent_requests_at: Time.zone.today) }
  scope :send_consent_reminders_today,
        -> { active.where(send_consent_reminders_at: Time.zone.today) }

  after_initialize :set_timeline_attributes
  after_validation :set_timeline_timestamps

  on_wizard_step :location, exact: true do
    validates :location_id, presence: true
  end

  on_wizard_step :when, exact: true do
    validates :date, presence: true

    validates :time_of_day, inclusion: { in: Session.time_of_days.keys }
  end

  on_wizard_step :cohort, exact: true do
    validates :patients, presence: true
  end

  on_wizard_step :timeline, exact: true do
    validates :send_consent_requests_at,
              presence: true,
              comparison: {
                greater_than_or_equal_to: -> { Time.zone.today },
                less_than_or_equal_to: ->(object) { object.date }
              }

    validates :reminder_days_after, inclusion: { in: %w[default custom] }
    validates :reminder_days_after_custom,
              presence: true,
              numericality: {
                greater_than_or_equal_to: 2,
                less_than_or_equal_to: 7
              },
              if: -> { reminder_days_after == "custom" }

    validates :close_consent_on, inclusion: { in: %w[default custom] }
    validates :close_consent_at,
              presence: true,
              if: -> { close_consent_on == "custom" }
  end

  def health_questions
    programme.vaccines.first.health_questions
  end

  def type
    programme.name
  end

  def in_progress?
    date.to_date == Time.zone.today
  end

  def wizard_steps
    %i[location when cohort timeline confirm]
  end

  def days_between_consent_and_session
    (date - send_consent_requests_at).to_i
  end

  def days_between_consent_and_reminder
    (send_consent_reminders_at - send_consent_requests_at).to_i
  end

  def unmatched_consent_forms
    consent_forms.unmatched.recorded.order(:recorded_at)
  end

  def open_for_consent?
    close_consent_at&.future?
  end

  private

  def set_timeline_attributes
    unless send_consent_reminders_at.nil?
      if send_consent_requests_at + DEFAULT_DAYS_FOR_REMINDER.days ==
           send_consent_reminders_at
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

    self.send_consent_reminders_at =
      send_consent_requests_at + reminder_days_after.days
    self.close_consent_at = close_consent_on
  end
end
