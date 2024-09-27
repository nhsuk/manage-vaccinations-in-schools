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

  attr_accessor :date

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

  after_save :ensure_session_date_exists

  validate :programmes_part_of_team

  on_wizard_step :when, exact: true do
    validates :date, presence: true
  end

  on_wizard_step :cohort, exact: true do
    validates :patients, presence: true
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

  def year_groups
    programmes.flat_map(&:year_groups).uniq.sort
  end

  def create_patient_sessions!
    return if location.nil?

    cohorts = team.cohorts.for_year_groups(year_groups)

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

    PatientSession.import!(patient_sessions, on_duplicate_key_update: [:active])
  end

  def set_consent_dates
    if dates.empty?
      self.send_consent_requests_at = nil
      self.send_consent_reminders_at = nil
      self.close_consent_at = nil
    else
      earliest_date = dates.map(&:value).min

      self.send_consent_requests_at =
        earliest_date -
          team.days_between_first_session_and_consent_requests.days

      self.send_consent_reminders_at =
        send_consent_requests_at +
          team.days_between_consent_requests_and_first_reminders.days

      latest_date = dates.map(&:value).max

      self.close_consent_at = latest_date - 1.day
    end
  end

  def wizard_steps
    %i[when cohort confirm]
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

    unless programmes.all? { team.programmes.include?(_1) }
      errors.add(:programmes, :inclusion)
    end
  end

  def set_programmes
    return unless new_record?
    return if location.nil? || team.nil?

    self.programmes =
      team.programmes.select { _1.year_groups.intersect?(location.year_groups) }
  end

  def ensure_session_date_exists
    return if date.nil?

    # TODO: Replace with UI to add/remove dates.
    ActiveRecord::Base.transaction do
      dates.destroy_all
      dates.create!(value: date)

      set_consent_dates

      # Temporary: to avoid callbacks calling this method again.
      update_columns(
        send_consent_requests_at:,
        send_consent_reminders_at:,
        close_consent_at:
      )
    end
  end
end
