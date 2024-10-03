# frozen_string_literal: true

# == Schema Information
#
# Table name: sessions
#
#  id                                  :bigint           not null, primary key
#  academic_year                       :integer          not null
#  close_consent_at                    :date
#  days_before_first_consent_reminder  :integer
#  days_between_consent_reminders      :integer
#  maximum_number_of_consent_reminders :integer
#  send_consent_requests_at            :date
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  location_id                         :bigint
#  team_id                             :bigint           not null
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
  audited

  belongs_to :team
  belongs_to :location, optional: true

  has_many :dates, -> { order(:value) }, class_name: "SessionDate"
  has_many :notifications, class_name: "SessionNotification"
  has_many :patient_sessions

  has_and_belongs_to_many :immunisation_imports
  has_and_belongs_to_many :programmes

  has_many :patients, through: :patient_sessions
  has_many :vaccines, through: :programmes
  has_many :batches, through: :vaccines

  accepts_nested_attributes_for :dates, allow_destroy: true

  scope :has_date,
        ->(value) { where(SessionDate.for_session.where(value:).arel.exists) }

  scope :has_programme,
        ->(programme) { joins(:programmes).where(programmes: programme) }

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

  scope :send_consent_requests,
        -> { scheduled.where("? >= send_consent_requests_at", Date.current) }
  scope :send_consent_reminders,
        -> do
          scheduled.where(
            "? >= send_consent_requests_at + days_before_first_consent_reminder",
            Date.current
          )
        end

  after_initialize :set_programmes

  validate :programmes_part_of_team

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

  def year_groups
    programmes.flat_map(&:year_groups).uniq.sort
  end

  def today_or_future_dates
    dates.select(&:today_or_future?).map(&:value)
  end

  def create_patient_sessions!
    return if location.nil?

    cohorts = team.cohorts.for_year_groups(year_groups, academic_year:)

    patients_in_cohorts =
      Patient.where(cohort: cohorts, school: location).includes(
        vaccination_records: :programme
      )

    required_programmes = Set.new(programmes)

    unvaccinated_patients =
      patients_in_cohorts.reject do |patient|
        # TODO: This logic doesn't work for vaccinations that require multiple doses.

        vaccinated_programmes =
          Set.new(
            patient
              .vaccination_records
              .select { _1.recorded? && _1.administered? }
              .map(&:programme)
          )

        required_programmes.subset?(vaccinated_programmes)
      end

    patient_sessions =
      unvaccinated_patients.map do
        PatientSession.new(patient: _1, session: self, active: true)
      end

    PatientSession.import!(
      patient_sessions,
      on_duplicate_key_update: {
        conflict_target: %i[patient_id session_id],
        columns: [:active]
      }
    )
  end

  def set_consent_dates
    if dates.empty?
      self.close_consent_at = nil
      self.days_before_first_consent_reminder = nil
      self.days_between_consent_reminders = nil
      self.maximum_number_of_consent_reminders = nil
      self.send_consent_requests_at = nil
    else
      self.send_consent_requests_at =
        dates.map(&:value).min -
          team.days_between_first_session_and_consent_requests.days

      self.days_before_first_consent_reminder =
        team.days_before_first_consent_reminder

      self.days_between_consent_reminders = team.days_between_consent_reminders

      self.maximum_number_of_consent_reminders =
        maximum_number_of_consent_reminders

      self.close_consent_at = dates.map(&:value).max - 1.day
    end
  end

  def send_consent_reminders_at
    if send_consent_requests_at.nil? || days_before_first_consent_reminder.nil?
      return nil
    end

    send_consent_requests_at + days_before_first_consent_reminder
  end

  def unmatched_consent_forms
    team.consent_forms.where(location:).unmatched.recorded.order(:recorded_at)
  end

  def open_for_consent?
    close_consent_at&.future?
  end

  private

  def set_programmes
    return unless new_record?
    return if location.nil?

    self.programmes =
      team.programmes.select { _1.year_groups.intersect?(location.year_groups) }
  end

  def programmes_part_of_team
    return if programmes.empty?

    unless programmes.all? { team.programmes.include?(_1) }
      errors.add(:programmes, :inclusion)
    end
  end
end
