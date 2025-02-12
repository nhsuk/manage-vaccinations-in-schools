# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_sessions
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  patient_id :bigint           not null
#  session_id :bigint           not null
#
# Indexes
#
#  index_patient_sessions_on_patient_id                 (patient_id)
#  index_patient_sessions_on_patient_id_and_session_id  (patient_id,session_id) UNIQUE
#  index_patient_sessions_on_session_id                 (session_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (session_id => sessions.id)
#

class PatientSession < ApplicationRecord
  audited

  include PatientSessionStatusConcern

  belongs_to :patient
  belongs_to :session

  has_one :location, through: :session
  has_one :team, through: :session
  has_one :organisation, through: :session
  has_many :programmes, through: :session
  has_many :session_attendances, dependent: :destroy

  has_many :gillick_assessments, -> { order(:created_at) }
  has_many :pre_screenings, -> { order(:created_at) }

  has_many :session_notifications,
           -> { where(session_id: _1.session_id) },
           through: :patient

  has_and_belongs_to_many :immunisation_imports

  scope :notification_not_sent,
        ->(session_date) do
          where.not(
            SessionNotification
              .where(
                "session_notifications.session_id = patient_sessions.session_id"
              )
              .where(
                "session_notifications.patient_id = patient_sessions.patient_id"
              )
              .where(session_date:)
              .arel
              .exists
          )
        end

  scope :preload_for_status,
        -> do
          preload(
            :gillick_assessments,
            :programmes,
            :session_attendances,
            patient: [:triages, { consents: :parent }, :vaccination_records]
          )
        end

  scope :order_by_name,
        -> do
          order("LOWER(patients.given_name)", "LOWER(patients.family_name)")
        end

  delegate :send_notifications?, to: :patient

  def able_to_vaccinate?
    !unable_to_vaccinate?
  end

  def safe_to_destroy?
    any_vaccination_records =
      programmes.any? do |programme|
        vaccination_records(programme:, for_session: true).present?
      end

    return false if any_vaccination_records

    gillick_assessments.empty? && session_attendances.none?(&:attending?)
  end

  def destroy_if_safe!
    destroy! if safe_to_destroy?
  end

  def consents(programme:)
    patient.consents.select { it.programme_id == programme.id }
  end

  def latest_consents(programme:)
    latest_consents_by_programme.fetch(programme.id, [])
  end

  def gillick_assessment(programme:)
    gillick_assessments.select { it.programme_id == programme.id }.last
  end

  def triages(programme:)
    patient.triages.select { it.programme_id == programme.id }
  end

  def latest_triage(programme:)
    latest_triage_by_programme[programme.id]
  end

  def vaccination_records(programme:, for_session: false)
    vaccination_records_for_programme =
      patient.vaccination_records.select { it.programme_id == programme.id }

    # Normally we would want to show all vaccination records for a patient regardless of
    # the session they were vaccinated in. However, there are some cases where it may be
    # necessary to show only vaccination records for this particular session.

    if for_session
      vaccination_records_for_programme.select { it.session_id == session_id }
    else
      vaccination_records_for_programme
    end
  end

  def todays_attendance
    @todays_attendance ||=
      if (session_date = session.session_dates.find(&:today?))
        session_attendances.eager_load(
          :patient,
          :session_date
        ).find_or_initialize_by(session_date:)
      end
  end

  def attending_today?
    todays_attendance&.attending?
  end

  private

  def latest_consents_by_programme
    @latest_consents_by_programme ||=
      patient
        .consents
        .reject(&:invalidated?)
        .select { it.response_given? || it.response_refused? }
        .group_by(&:programme_id)
        .transform_values do |consents|
          consents.group_by(&:name).map { it.second.max_by(&:created_at) }
        end
  end

  def latest_triage_by_programme
    @latest_triage_by_programme ||=
      patient
        .triages
        .reject(&:invalidated?)
        .group_by(&:programme_id)
        .transform_values { it.max_by(&:created_at) }
  end
end
