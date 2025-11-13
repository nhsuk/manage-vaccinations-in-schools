# frozen_string_literal: true

# == Schema Information
#
# Table name: sessions
#
#  id                            :bigint           not null, primary key
#  academic_year                 :integer          not null
#  dates                         :date             not null, is an Array
#  days_before_consent_reminders :integer
#  national_protocol_enabled     :boolean          default(FALSE), not null
#  programme_types               :enum             not null, is an Array
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
#  index_sessions_on_academic_year_and_location_id_and_team_id  (academic_year,location_id,team_id)
#  index_sessions_on_dates                                      (dates) USING gin
#  index_sessions_on_location_id                                (location_id)
#  index_sessions_on_location_id_and_academic_year_and_team_id  (location_id,academic_year,team_id)
#  index_sessions_on_programme_types                            (programme_types) USING gin
#  index_sessions_on_team_id_and_academic_year                  (team_id,academic_year)
#  index_sessions_on_team_id_and_location_id                    (team_id,location_id)
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#
class Session < ApplicationRecord
  include Consentable
  include ContributesToPatientTeams
  include DaysBeforeToWeeksBefore
  include Delegatable
  include GelatineVaccinesConcern
  include HasLocationProgrammeYearGroups
  include HasManyProgrammes

  class ActiveRecord_Relation < ActiveRecord::Relation
    include ContributesToPatientTeams::Relation
  end

  audited associated_with: :location
  has_associated_audits

  belongs_to :team
  belongs_to :location

  has_many :consent_notifications
  has_many :notes
  has_many :session_notifications
  has_many :session_programmes,
           -> { joins(:programme).order(:"programmes.type") },
           dependent: :destroy,
           autosave: true
  has_many :vaccination_records, -> { kept }

  has_and_belongs_to_many :immunisation_imports

  has_many :gillick_assessments,
           -> { where(date: it.dates) },
           through: :location
  has_many :pre_screenings, -> { where(date: it.dates) }, through: :location
  has_many :attendance_records, -> { where(date: it.dates) }, through: :location

  has_many :patient_locations,
           -> { where(academic_year: it.academic_year) },
           through: :location

  has_one :organisation, through: :team
  has_one :subteam, through: :location
  has_many :programmes, through: :session_programmes
  has_many :vaccines, through: :programmes

  has_many :location_year_groups,
           -> { where(academic_year: it.academic_year) },
           through: :location

  has_many :location_programme_year_groups,
           -> do
             includes(:location_year_group).where(programme: it.programmes)
           end,
           through: :location_year_groups

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
    INNER JOIN location_year_groups
    ON location_year_groups.location_id = sessions.location_id
    AND location_year_groups.academic_year = sessions.academic_year
    AND location_year_groups.value = sessions.academic_year - patients.birth_academic_year - #{Integer::AGE_CHILDREN_START_SCHOOL}
    INNER JOIN location_programme_year_groups
    ON location_programme_year_groups.location_year_group_id = location_year_groups.id
    AND location_programme_year_groups.programme_id = session_programmes.programme_id
  SQL

  scope :has_date, ->(value) { where("dates @> ARRAY[?]::date[]", value) }

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
  scope :unscheduled, -> { where(dates: []) }
  scope :scheduled,
        -> do
          where(
            "? <= (SELECT max(date_value) FROM unnest(dates) date_value)",
            Date.current
          )
        end
  scope :completed,
        -> do
          where(
            "? > (SELECT max(date_value) FROM unnest(dates) date_value)",
            Date.current
          )
        end

  scope :search_by_name,
        ->(query) { joins(:location).merge(Location.search_by_name(query)) }

  scope :order_by_earliest_date,
        -> do
          order(
            Arel.sql(
              "CASE WHEN (SELECT min(date_value) FROM unnest(sessions.dates) date_value) >= ? THEN 1 ELSE 2 END",
              Date.current
            ),
            Arel.sql(
              "(SELECT min(date_value) FROM unnest(sessions.dates) date_value) ASC NULLS LAST"
            )
          )
        end

  scope :send_consent_requests,
        -> { scheduled.where("? >= send_consent_requests_at", Date.current) }
  scope :send_consent_reminders,
        -> do
          scheduled.where(
            "? >= (SELECT min(date_value) FROM unnest(dates) date_value) - days_before_consent_reminders",
            Date.current
          )
        end
  scope :send_invitations,
        -> { scheduled.where("? >= send_invitations_at", Date.current) }

  scope :registration_not_required, -> { where(requires_registration: false) }

  before_create :set_slug

  delegate :clinic?, :generic_clinic?, :school?, to: :location

  def patients
    birth_academic_years =
      location_programme_year_groups.pluck_birth_academic_years

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

  def scheduled? = !unscheduled? && !completed?

  def started?
    return false if dates.empty?
    Date.current >= dates.min
  end

  def vaccine_methods
    @vaccine_methods ||= programmes.flat_map(&:vaccine_methods).uniq.sort
  end

  def has_multiple_vaccine_methods? = vaccine_methods.length > 1

  def programmes_for(year_group: nil, patient: nil)
    year_group ||= patient.year_group(academic_year:)

    programmes.select do |programme|
      location_programme_year_groups.any? do
        it.programme_id == programme.id &&
          it.location_year_group.value == year_group
      end
    end
  end

  def today_or_future_dates
    dates.select { it.today? || it.future? }
  end

  def future_dates = dates.select(&:future?)

  def next_date(include_today:)
    (include_today ? today_or_future_dates : future_dates).first
  end

  def has_been_attended?(date:)
    gillick_assessments.any? { it.date == date } ||
      pre_screenings.any? { it.date == date } ||
      attendance_records.any? { it.date == date }
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

  def patients_with_no_consent_response_count
    patients.has_consent_status(
      "no_response",
      programme: programmes,
      academic_year:
    ).count
  end

  private

  def set_slug
    self.slug = SecureRandom.alphanumeric(10) if slug.nil?
  end
end
