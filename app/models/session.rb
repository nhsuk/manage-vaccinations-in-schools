# frozen_string_literal: true

# == Schema Information
#
# Table name: sessions
#
#  id                            :bigint           not null, primary key
#  academic_year                 :integer          not null
#  closed_at                     :datetime
#  days_before_consent_reminders :integer
#  send_consent_requests_at      :date
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  location_id                   :bigint           not null
#  team_id                       :bigint           not null
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
  belongs_to :location

  has_many :dates, -> { order(:value) }, class_name: "SessionDate"
  has_many :notifications, class_name: "SessionNotification"
  has_many :patient_sessions

  has_and_belongs_to_many :immunisation_imports
  has_and_belongs_to_many :programmes

  has_many :patients, through: :patient_sessions
  has_many :vaccines, through: :programmes

  accepts_nested_attributes_for :dates, allow_destroy: true

  scope :has_date,
        ->(value) { where(SessionDate.for_session.where(value:).arel.exists) }

  scope :has_programme,
        ->(programme) { joins(:programmes).where(programmes: programme) }

  scope :today, -> { has_date(Date.current) }

  scope :for_current_academic_year,
        -> { where(academic_year: Date.current.academic_year) }

  scope :upcoming, -> { for_current_academic_year.where(closed_at: nil) }
  scope :unscheduled,
        -> { upcoming.where.not(SessionDate.for_session.arel.exists) }
  scope :scheduled,
        -> do
          upcoming.where(
            "? <= (?)",
            Date.current,
            SessionDate.for_session.select("MAX(value)")
          )
        end
  scope :completed,
        -> do
          upcoming.where(
            "? > (?)",
            Date.current,
            SessionDate.for_session.select("MAX(value)")
          )
        end
  scope :closed, -> { for_current_academic_year.where.not(closed_at: nil) }

  scope :send_consent_requests,
        -> { scheduled.where("? >= send_consent_requests_at", Date.current) }
  scope :send_consent_reminders,
        -> do
          scheduled.where(
            "? >= (?) - days_before_consent_reminders",
            Date.current,
            SessionDate.for_session.select("MIN(value)")
          )
        end

  validates :programmes, presence: true
  validate :programmes_part_of_team

  def open?
    closed_at.nil?
  end

  def today?
    dates.map(&:value).include?(Date.current)
  end

  def unscheduled?
    dates.empty?
  end

  def completed?
    return false if dates.empty?
    Date.current > dates.map(&:value).max
  end

  def closed?
    closed_at != nil
  end

  def year_groups
    programmes.flat_map(&:year_groups).uniq.sort
  end

  def today_or_future_dates
    dates.select(&:today_or_future?).map(&:value)
  end

  def <=>(other)
    [dates.first&.value, location.type, location.name] <=>
      [other.dates.first&.value, other.location.type, other.location.name]
  end

  def create_patient_sessions!
    cohorts = team.cohorts.for_year_groups(year_groups, academic_year:)

    patients_scope =
      Patient
        .includes(:upcoming_sessions, vaccination_records: :programme)
        .where(cohort: cohorts)
        .not_deceased

    patients_in_cohorts =
      if location.school?
        patients_scope.where(school: location)
      elsif location.generic_clinic?
        patients_scope.where(home_educated: true).or(
          patients_scope.where(school: nil)
        )
      elsif location.community_clinic?
        patients_scope.none # TODO: handle community clinics
      end

    unvaccinated_patients =
      patients_in_cohorts.reject do |patient|
        programmes.all? { |programme| patient.vaccinated?(programme) }
      end

    # First we remove patients from any other upcoming sessions.
    unvaccinated_patients.each do |patient|
      sessions_other_than_self = patient.upcoming_sessions.reject { _1 == self }
      next if sessions_other_than_self.empty?

      patient
        .patient_sessions
        .where(session: sessions_other_than_self)
        .find_each(&:destroy_if_safe!)
    end

    # Next we can add the unvaccinated patients to this session.
    PatientSession.import!(
      %i[patient_id session_id],
      unvaccinated_patients.map { [_1.id, id] },
      on_duplicate_key_ignore: true
    )
  end

  def close!
    return if closed?

    ActiveRecord::Base.transaction do
      unvaccinated_patients =
        patients.reject do |patient|
          programmes.all? { |programme| patient.vaccinated?(programme) }
        end

      generic_clinic_session_id = team.generic_clinic_session.id

      PatientSession.import!(
        %i[patient_id session_id],
        unvaccinated_patients.map { [_1.id, generic_clinic_session_id] },
        on_duplicate_key_ignore: true
      )

      update!(closed_at: Time.current)
    end
  end

  def set_consent_dates
    if dates.empty?
      self.days_before_consent_reminders = nil
      self.send_consent_requests_at = nil
    else
      self.send_consent_requests_at =
        dates.map(&:value).min - team.days_before_consent_requests.days

      self.days_before_consent_reminders = team.days_before_consent_reminders
    end
  end

  def send_consent_reminders_at
    return nil if dates.empty? || days_before_consent_reminders.nil?

    dates.map(&:value).min - team.days_before_consent_reminders.days
  end

  def close_consent_at
    return nil if dates.empty?
    dates.map(&:value).max - 1.day
  end

  def weeks_before_consent_reminders
    (days_before_consent_reminders / 7).to_i
  end

  def weeks_before_consent_reminders=(value)
    self.days_before_consent_reminders = value * 7
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
