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
#  send_invitations_at           :date
#  slug                          :string           not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  location_id                   :bigint           not null
#  organisation_id               :bigint           not null
#
# Indexes
#
#  idx_on_organisation_id_location_id_academic_year_3496b72d0c  (organisation_id,location_id,academic_year) UNIQUE
#  index_sessions_on_organisation_id                            (organisation_id)
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#
class Session < ApplicationRecord
  audited

  belongs_to :organisation
  belongs_to :location

  has_many :consent_notifications
  has_many :patient_sessions
  has_many :session_dates, -> { order(:value) }
  has_many :session_notifications

  has_and_belongs_to_many :immunisation_imports
  has_and_belongs_to_many :programmes

  has_one :team, through: :location
  has_many :patients, through: :patient_sessions
  has_many :vaccines, through: :programmes

  accepts_nested_attributes_for :session_dates, allow_destroy: true

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
  scope :send_invitations,
        -> { scheduled.where("? >= send_invitations_at", Date.current) }

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

  validates :programmes, presence: true
  validate :programmes_part_of_organisation

  before_create :set_slug

  def to_param
    slug
  end

  def open?
    closed_at.nil?
  end

  def today?
    dates.any?(&:today?)
  end

  def unscheduled?
    dates.empty?
  end

  def completed?
    return false if dates.empty?
    Date.current > dates.max
  end

  def started?
    return false if dates.empty?
    Date.current > dates.min
  end

  def closed?
    closed_at != nil
  end

  def closable?
    open? && completed?
  end

  def year_groups
    programmes.flat_map(&:year_groups).uniq.sort
  end

  def dates
    session_dates.map(&:value).compact
  end

  def today_or_future_dates
    dates.select { _1.today? || _1.future? }
  end

  def future_dates
    dates.select(&:future?)
  end

  def can_change_notification_dates?
    consent_notifications.empty? && session_notifications.empty?
  end

  def <=>(other)
    [dates.first, location.type, location.name] <=>
      [other.dates.first, other.location.type, other.location.name]
  end

  def create_patient_sessions!
    cohorts = organisation.cohorts.for_year_groups(year_groups, academic_year:)

    patients_scope =
      Patient
        .includes(:upcoming_sessions, vaccination_records: :programme)
        .where(cohort: cohorts)
        .or(Patient.in_pending_cohorts(cohorts))
        .not_deceased

    patients_in_cohorts =
      if location.school?
        patients_scope.where(school: location).or(
          patients_scope.in_pending_school(location)
        )
      elsif location.generic_clinic?
        patients_scope.where(home_educated: true).or(
          patients_scope.where(school: nil)
        )
      elsif location.community_clinic?
        patients_scope.none # TODO: handle community clinics
      end

    unvaccinated_patients_in_cohorts =
      patients_in_cohorts.unvaccinated_for(programmes:)

    # Mark existing patient sessions for transfer
    unvaccinated_patients_in_cohorts.each do |patient|
      other_sessions = patient.upcoming_sessions.reject { _1 == self }
      next if other_sessions.empty?

      patient
        .patient_sessions
        .where(session: other_sessions)
        .update_all(proposed_session_id: id)
    end

    # Remove patients that have other upcoming sessions
    unvaccinated_patients_in_cohorts.reject! { _1.upcoming_sessions.any? }

    # Add unvaccinated patients to this session
    PatientSession.import!(
      %i[patient_id session_id],
      unvaccinated_patients_in_cohorts.map { [_1.id, id] },
      on_duplicate_key_ignore: true
    )
  end

  def unvaccinated_patients
    patients.unvaccinated_for(programmes:)
  end

  def close!
    return if closed?
    return unless completed?

    ActiveRecord::Base.transaction do
      generic_clinic_session_id = organisation.generic_clinic_session.id

      PatientSession.import!(
        %i[patient_id session_id],
        unvaccinated_patients.map { [_1.id, generic_clinic_session_id] },
        on_duplicate_key_ignore: true
      )

      update!(closed_at: Time.current)
    end
  end

  def set_notification_dates
    if earliest_date
      if location.generic_clinic?
        self.days_before_consent_reminders = nil
        self.send_consent_requests_at = nil
        self.send_invitations_at =
          earliest_date - organisation.days_before_invitations.days
      else
        self.days_before_consent_reminders =
          organisation.days_before_consent_reminders
        self.send_consent_requests_at =
          earliest_date - organisation.days_before_consent_requests.days
        self.send_invitations_at = nil
      end
    else
      self.days_before_consent_reminders = nil
      self.send_consent_requests_at = nil
      self.send_invitations_at = nil
    end
  end

  def send_consent_reminders_at
    return nil if dates.empty? || days_before_consent_reminders.nil?

    reminder_dates = dates.map { _1 - days_before_consent_reminders.days }
    reminder_dates.find(&:future?) || reminder_dates.last
  end

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

  def patient_sessions_moving_from_this_session
    patient_sessions.pending_transfer
  end

  def patient_sessions_moving_to_this_session
    organisation.patient_sessions.where(proposed_session: self)
  end

  def has_movers?
    patient_sessions_moving_from_this_session.any? ||
      patient_sessions_moving_to_this_session.any?
  end

  private

  def set_slug
    self.slug = SecureRandom.alphanumeric(10) if slug.nil?
  end

  def programmes_part_of_organisation
    return if programmes.empty?

    unless programmes.all? { organisation.programmes.include?(_1) }
      errors.add(:programmes, :inclusion)
    end
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
