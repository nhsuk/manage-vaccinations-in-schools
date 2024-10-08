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

  scope :today, -> { has_date(Date.current).order_by_location_name }

  scope :order_by_location_name,
        -> { left_joins(:location).order("locations.name ASC NULLS LAST") }

  scope :unscheduled,
        -> do
          where(academic_year: Date.current.academic_year).where.not(
            SessionDate.for_session.arel.exists
          )
        end

  scope :scheduled,
        -> do
          where(
            "? <= (?)",
            Date.current,
            SessionDate.for_session.select("MAX(value)")
          )
        end

  scope :upcoming, -> { scheduled.or(unscheduled) }

  scope :completed,
        -> do
          where(academic_year: Date.current.academic_year).where(
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

  validates :programmes, presence: true
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
      Patient
        .recorded
        .where(cohort: cohorts, school: location)
        .includes(:upcoming_sessions, vaccination_records: :programme)

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

    unvaccinated_patients.each do |patient|
      sessions_other_than_self = patient.upcoming_sessions.reject { _1 == self }
      next if sessions_other_than_self.empty?

      patient
        .patient_sessions
        .where(session: sessions_other_than_self)
        .select(&:added_to_session?)
        .each(&:destroy!)
    end

    PatientSession.import!(
      %i[patient_id session_id],
      unvaccinated_patients.map { [_1.id, id] },
      on_duplicate_key_ignore: true
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

  def programmes_part_of_team
    return if programmes.empty?

    unless programmes.all? { team.programmes.include?(_1) }
      errors.add(:programmes, :inclusion)
    end
  end
end
