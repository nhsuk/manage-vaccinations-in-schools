# frozen_string_literal: true

# == Schema Information
#
# Table name: sessions
#
#  id                        :bigint           not null, primary key
#  academic_year             :integer          not null
#  close_consent_at          :date
#  send_consent_reminders_at :date
#  send_consent_requests_at  :date
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  location_id               :bigint
#  team_id                   :bigint           not null
#
# Indexes
#
#  index_sessions_on_team_id                                    (team_id)
#  index_sessions_on_team_id_and_location_id_and_academic_year  (team_id,location_id,academic_year) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#
class Session < ApplicationRecord
  include WizardStepConcern

  audited

  DEFAULT_DAYS_FOR_REMINDER = 2

  attr_accessor :date,
                :reminder_days_after,
                :reminder_days_after_custom,
                :close_consent_on

  belongs_to :team
  belongs_to :location, optional: true

  has_many :consent_forms
  has_many :dates, class_name: "SessionDate"
  has_many :patient_sessions

  has_and_belongs_to_many :immunisation_imports
  has_and_belongs_to_many :programmes

  has_many :patients, through: :patient_sessions
  has_many :vaccines, through: :programmes
  has_many :batches, through: :vaccines

  scope :has_date,
        ->(value) { where(SessionDate.for_session.where(value:).arel.exists) }

  scope :today, -> { has_date(Date.current) }

  scope :unscheduled, -> { where.not(SessionDate.for_session.arel.exists) }

  scope :scheduled,
        -> do
          where(
            "? <= (?)",
            Date.current,
            SessionDate.for_session.select("MAX(value)")
          )
        end

  scope :completed,
        -> do
          where(
            "? > (?)",
            Date.current,
            SessionDate.for_session.select("MAX(value)")
          )
        end

  scope :send_consent_requests_today,
        -> { where(send_consent_requests_at: Time.zone.today) }
  scope :send_consent_reminders_today,
        -> { where(send_consent_reminders_at: Time.zone.today) }

  after_initialize :set_programmes

  after_initialize :set_timeline_attributes
  after_validation :set_timeline_timestamps

  after_save :ensure_session_date_exists

  validate :programmes_part_of_team

  on_wizard_step :when, exact: true do
    validates :date, presence: true
  end

  on_wizard_step :cohort, exact: true do
    validates :patients, presence: true
  end

  on_wizard_step :timeline, exact: true do
    validates :send_consent_requests_at,
              presence: true,
              comparison: {
                greater_than_or_equal_to: -> { Time.zone.today },
                less_than_or_equal_to: ->(object) do
                  object.dates.map(&:value).min
                end
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

  def today?
    dates.map(&:value).include?(Date.current)
  end

  def unscheduled?
    dates.empty?
  end

  def completed?
    return false if unscheduled?
    Date.current > dates.map(&:value).max
  end

  def wizard_steps
    %i[when cohort timeline confirm]
  end

  def days_between_consent_and_session
    (dates.map(&:value).min - send_consent_requests_at).to_i
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

  def programmes_part_of_team
    return if programmes.empty?

    errors.add(:programmes, :inclusion) if programmes.map(&:team).uniq != [team]
  end

  def set_programmes
    return unless new_record?
    return if location.nil? || team.nil?

    self.programmes =
      team.programmes.select { _1.year_groups.intersect?(location.year_groups) }
  end

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
      self.close_consent_on =
        close_consent_at == dates.map(&:value).min ? "default" : "custom"
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
      (
        if self.close_consent_on == "default"
          dates.map(&:value).min
        else
          close_consent_at
        end
      )

    self.send_consent_reminders_at =
      send_consent_requests_at + reminder_days_after.days
    self.close_consent_at = close_consent_on
  end

  def ensure_session_date_exists
    return if date.nil?

    # TODO: Replace with UI to add/remove dates.
    ActiveRecord::Base.transaction do
      dates.delete_all
      dates.create!(value: date)
    end
  end
end
