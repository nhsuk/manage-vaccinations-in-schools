# frozen_string_literal: true

# == Schema Information
#
# Table name: sessions
#
#  id                            :bigint           not null, primary key
#  academic_year                 :integer          not null
#  days_before_consent_reminders :integer
#  national_protocol_enabled     :boolean          default(FALSE), not null
#  psd_enabled                   :boolean          default(FALSE), not null
#  requires_registration         :boolean          default(TRUE), not null
#  send_consent_requests_at      :date
#  send_invitations_at           :date
#  slug                          :string           not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  location_id                   :bigint           not null
#  team_id                       :bigint           not null
#
# Indexes
#
#  index_sessions_on_location_id                                (location_id)
#  index_sessions_on_location_id_and_academic_year_and_team_id  (location_id,academic_year,team_id)
#  index_sessions_on_team_id_and_academic_year                  (team_id,academic_year)
#  index_sessions_on_team_id_and_location_id                    (team_id,location_id)
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#
class Session < ApplicationRecord
  include HasProgrammeYearGroups

  audited associated_with: :location
  has_associated_audits

  belongs_to :team
  belongs_to :location

  has_many :consent_notifications
  has_many :notes
  has_many :session_dates, -> { order(:value) }
  has_many :session_notifications
  has_many :session_programmes,
           -> { joins(:programme).order(:"programmes.type") },
           dependent: :destroy
  has_many :vaccination_records, -> { kept }

  has_and_belongs_to_many :immunisation_imports

  has_many :patient_locations,
           -> { where(academic_year: it.academic_year) },
           through: :location

  has_one :organisation, through: :team
  has_one :subteam, through: :location
  has_many :pre_screenings, through: :session_dates
  has_many :programmes, through: :session_programmes
  has_many :gillick_assessments, through: :session_dates
  has_many :patients, through: :patient_locations
  has_many :vaccines, through: :programmes

  has_many :location_programme_year_groups,
           -> { where(programme: it.programmes) },
           through: :location

  accepts_nested_attributes_for :session_dates, allow_destroy: true

  scope :joins_patient_locations, -> { joins(<<-SQL) }
    INNER JOIN patient_locations
    ON patient_locations.location_id = sessions.location_id
    AND patient_locations.academic_year = sessions.academic_year
  SQL

  scope :joins_patients, -> { joins(<<-SQL) }
    INNER JOIN patients
    ON patients.id = patient_locations.patient_id
  SQL

  scope :joins_location_programme_year_groups, -> { joins(<<-SQL) }
    INNER JOIN location_programme_year_groups
    ON location_programme_year_groups.location_id = sessions.location_id
    AND location_programme_year_groups.programme_id = session_programmes.programme_id
    AND location_programme_year_groups.year_group = sessions.academic_year - patients.birth_academic_year - #{Integer::AGE_CHILDREN_START_SCHOOL}
  SQL

  scope :has_date,
        ->(value) { where(SessionDate.for_session.where(value:).arel.exists) }

  scope :has_programmes,
        ->(programmes) do
          where(
            "(?) >= ?",
            SessionProgramme
              .select("COUNT(session_programmes.id)")
              .where("sessions.id = session_programmes.session_id")
              .where(programme: programmes),
            programmes.count
          )
        end

  scope :supports_delegation,
        -> { has_programmes(Programme.supports_delegation) }

  scope :in_progress, -> { has_date(Date.current) }
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

  scope :search_by_name,
        ->(query) { joins(:location).merge(Location.search_by_name(query)) }

  scope :join_earliest_date,
        -> do
          joins(
            "LEFT JOIN (SELECT session_id, MIN(value) AS value " \
              "FROM session_dates GROUP BY session_id) earliest_session_dates " \
              "ON sessions.id = earliest_session_dates.session_id"
          )
        end

  scope :order_by_earliest_date,
        -> do
          join_earliest_date.order(
            Arel.sql(
              "CASE WHEN earliest_session_dates.value >= ? THEN 1 ELSE 2 END",
              Date.current
            ),
            "earliest_session_dates.value ASC NULLS LAST"
          )
        end

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
  scope :send_invitations,
        -> { scheduled.where("? >= send_invitations_at", Date.current) }

  scope :registration_not_required, -> { where(requires_registration: false) }

  validates :send_consent_requests_at,
            presence: true,
            comparison: {
              greater_than_or_equal_to: :earliest_send_notifications_at,
              less_than_or_equal_to: :latest_send_consent_requests_at
            },
            unless: -> do
              earliest_send_notifications_at.nil? ||
                latest_send_consent_requests_at.nil? || location.generic_clinic?
            end

  validates :send_invitations_at,
            presence: true,
            comparison: {
              greater_than_or_equal_to: :earliest_send_notifications_at,
              less_than: :earliest_date
            },
            if: -> { earliest_date.present? && location.generic_clinic? }

  validates :weeks_before_consent_reminders,
            presence: true,
            comparison: {
              greater_than_or_equal_to: 1,
              less_than_or_equal_to: :maximum_weeks_before_consent_reminders
            },
            unless: -> do
              maximum_weeks_before_consent_reminders.nil? ||
                location.generic_clinic?
            end

  validates :programme_ids, presence: true

  before_create :set_slug

  delegate :clinic?, :generic_clinic?, :school?, to: :location

  def programme_birth_academic_years
    @programme_birth_academic_years ||=
      ProgrammeBirthAcademicYears.new(programme_year_groups, academic_year:)
  end

  def patients
    birth_academic_years =
      location_programme_year_groups.pluck_birth_academic_years(academic_year:)

    Patient
      .joins_sessions
      .where(sessions: { id: })
      .where(birth_academic_year: birth_academic_years)
  end

  def to_param = slug

  def today? = dates.any?(&:today?)

  def unscheduled? = dates.empty?

  def completed?
    return false if dates.empty?
    Date.current > dates.max
  end

  def started?
    return false if dates.empty?
    Date.current > dates.min
  end

  def supports_delegation? = programmes.any?(&:supports_delegation?)

  def pgd_supply_enabled? = supports_delegation? && !psd_enabled?

  def year_groups
    @year_groups ||= location_programme_year_groups.pluck_year_groups
  end

  def vaccine_methods
    @vaccine_methods ||= programmes.flat_map(&:vaccine_methods).uniq.sort
  end

  def has_multiple_vaccine_methods? = vaccine_methods.length > 1

  def programmes_for(year_group: nil, patient: nil)
    year_group ||= patient.year_group(academic_year:)

    programmes.select do |programme|
      location_programme_year_groups.any? do
        it.programme_id == programme.id && it.year_group == year_group
      end
    end
  end

  def dates
    session_dates.map(&:value).compact
  end

  def today_or_future_dates
    dates.select { it.today? || it.future? }
  end

  def future_dates
    dates.select(&:future?)
  end

  def next_date(include_today:)
    (include_today ? today_or_future_dates : future_dates).first
  end

  def can_change_notification_dates?
    consent_notifications.empty? && session_notifications.empty?
  end

  def can_send_clinic_invitations?
    if clinic?
      next_date(include_today: true) && !completed?
    else
      completed? &&
        team.generic_clinic_session(academic_year:).next_date(
          include_today: true
        )
    end
  end

  def set_notification_dates
    if earliest_date
      if location.generic_clinic?
        self.days_before_consent_reminders = nil
        self.send_consent_requests_at = nil
        self.send_invitations_at =
          earliest_date - team.days_before_invitations.days
      else
        self.days_before_consent_reminders = team.days_before_consent_reminders
        self.send_consent_requests_at =
          earliest_date - team.days_before_consent_requests.days
        self.send_invitations_at = nil
      end
    else
      self.days_before_consent_reminders = nil
      self.send_consent_requests_at = nil
      self.send_invitations_at = nil
    end
  end

  def next_reminder_dates
    return [] if days_before_consent_reminders.nil?

    reminder_dates = dates.map { it - days_before_consent_reminders.days }
    reminder_dates.select(&:future?)
  end

  def open_consent_at = send_consent_requests_at

  def close_consent_at
    return nil if dates.empty?
    dates.max - 1.day
  end

  def weeks_before_consent_reminders
    return nil if days_before_consent_reminders.nil?
    (days_before_consent_reminders / 7).to_i
  end

  def weeks_before_consent_reminders=(value)
    self.days_before_consent_reminders = (value.blank? ? nil : value.to_i * 7)
  end

  def open_for_consent?
    close_consent_at&.today? || close_consent_at&.future? || false
  end

  def next_reminder_date = next_reminder_dates.first

  def patients_with_no_consent_response_count
    patient_locations.has_consent_status(
      "no_response",
      programme: programmes
    ).count
  end

  private

  def set_slug
    self.slug = SecureRandom.alphanumeric(10) if slug.nil?
  end

  def earliest_date
    dates.min
  end

  def earliest_send_notifications_at
    return nil if earliest_date.nil?
    earliest_date - 3.months
  end

  def latest_send_consent_requests_at
    return nil if earliest_date.nil? || days_before_consent_reminders.nil?
    earliest_date - days_before_consent_reminders.days - 1
  end

  def maximum_weeks_before_consent_reminders
    return nil if earliest_date.nil? || send_consent_requests_at.nil?
    (earliest_date - send_consent_requests_at).to_i / 7
  end
end
