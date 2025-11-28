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
#  psd_enabled                   :boolean          default(FALSE), not null
#  requires_registration         :boolean          default(TRUE), not null
#  send_consent_requests_at      :date
#  send_invitations_at           :date
#  slug                          :string           not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  location_id                   :bigint           not null
#  team_id                       :bigint           not null
#  team_location_id              :bigint
#
# Indexes
#
#  index_sessions_on_academic_year_and_location_id_and_team_id  (academic_year,location_id,team_id)
#  index_sessions_on_dates                                      (dates) USING gin
#  index_sessions_on_location_id                                (location_id)
#  index_sessions_on_location_id_and_academic_year_and_team_id  (location_id,academic_year,team_id)
#  index_sessions_on_team_id_and_academic_year                  (team_id,academic_year)
#  index_sessions_on_team_id_and_location_id                    (team_id,location_id)
#  index_sessions_on_team_location_id                           (team_location_id)
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#  fk_rails_...  (team_location_id => team_locations.id)
#
class Session < ApplicationRecord
  include Consentable
  include ContributesToPatientTeams
  include DaysBeforeToWeeksBefore
  include Delegatable
  include GelatineVaccinesConcern

  class ActiveRecord_Relation < ActiveRecord::Relation
    include ContributesToPatientTeams::Relation
  end

  audited associated_with: :location
  has_associated_audits

  belongs_to :location
  belongs_to :team
  belongs_to :team_location, optional: true

  has_many :consent_notifications
  has_many :notes
  has_many :session_notifications
  has_many :session_programme_year_groups,
           class_name: "Session::ProgrammeYearGroup",
           dependent: :destroy
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

  scope :joins_patient_locations, -> { joins(<<-SQL) }
    INNER JOIN patient_locations
    ON patient_locations.location_id = sessions.location_id
    AND patient_locations.academic_year = sessions.academic_year
  SQL

  scope :joins_patients, -> { joins(<<-SQL) }
    INNER JOIN patients
    ON patients.id = patient_locations.patient_id
  SQL

  scope :joins_session_programme_year_groups, -> { joins(<<-SQL) }
    INNER JOIN session_programme_year_groups
    ON session_programme_year_groups.session_id = sessions.id
    AND session_programme_year_groups.year_group = sessions.academic_year - patients.birth_academic_year - #{Integer::AGE_CHILDREN_START_SCHOOL}
  SQL

  scope :has_date, ->(value) { where("dates @> ARRAY[?]::date[]", value) }

  scope :has_all_programme_types_of,
        ->(values) do
          where(
            "(?) >= ?",
            Session::ProgrammeYearGroup
              .select(
                "COUNT(DISTINCT session_programme_year_groups.programme_type)"
              )
              .where("sessions.id = session_programme_year_groups.session_id")
              .where(programme_type: values),
            values.count
          )
        end

  scope :has_any_programme_types_of,
        ->(values) do
          where(
            "(?) >= 1",
            Session::ProgrammeYearGroup
              .select(
                "COUNT(DISTINCT session_programme_year_groups.programme_type)"
              )
              .where("sessions.id = session_programme_year_groups.session_id")
              .where(programme_type: values)
          )
        end

  scope :has_all_programmes_of,
        ->(programmes) { has_all_programme_types_of(programmes.map(&:type)) }

  scope :has_any_programmes_of,
        ->(programmes) { has_any_programme_types_of(programmes.map(&:type)) }

  scope :supports_delegation,
        -> do
          has_any_programme_types_of(Programme::TYPES_SUPPORTING_DELEGATION)
        end

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

  def to_param = slug

  def programme_types
    @programme_types ||=
      session_programme_year_groups.map(&:programme_type).sort.uniq
  end

  def programmes = Programme.find_all(programme_types)

  def vaccines
    @vaccines ||= Vaccine.where(programme_type: programme_types)
  end

  def year_groups(programme: nil)
    if programme
      session_programme_year_groups.where(
        programme_type: programme.type
      ).pluck_year_groups
    else
      session_programme_year_groups.pluck_year_groups
    end
  end

  def birth_academic_years(programme: nil)
    if programme
      session_programme_year_groups.where(
        programme_type: programme.type
      ).pluck_birth_academic_years
    else
      session_programme_year_groups.pluck_birth_academic_years
    end
  end

  def patients
    Patient
      .joins_sessions
      .where(sessions: { id: })
      .where(birth_academic_year: birth_academic_years)
  end

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
      session_programme_year_groups.any? do
        it.programme_type == programme.type && it.year_group == year_group
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

  def sync_location_programme_year_groups!(programmes:)
    location_programme_year_groups =
      Location::ProgrammeYearGroup
        .joins(:location_year_group)
        .where(
          location_year_group: {
            location_id:,
            academic_year:
          },
          programme_type: programmes.map(&:type)
        )
        .pluck(:programme_type, :"location_year_group.value")

    rows =
      location_programme_year_groups.map do |programme_type, year_group|
        [id, programme_type, year_group]
      end

    ActiveRecord::Base.transaction do
      Session::ProgrammeYearGroup.where(session_id: id).delete_all
      Session::ProgrammeYearGroup.import!(
        %i[session_id programme_type year_group],
        rows,
        on_duplicate_key_ignore: true
      )
    end
  end

  private

  def set_slug
    self.slug = SecureRandom.alphanumeric(10) if slug.nil?
  end
end
