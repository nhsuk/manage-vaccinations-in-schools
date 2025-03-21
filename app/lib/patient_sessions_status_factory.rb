# frozen_string_literal: true

class PatientSessionsStatusFactory
  def initialize(patient_sessions: nil, session: nil)
    @patient_sessions =
      patient_sessions ||
        session
          .patient_sessions
          .eager_load(:patient)
          .preload(session: :programmes)
  end

  def call
    consent_statuses = build_patient_consent_statuses

    ActiveRecord::Base.transaction do
      Patient::ConsentStatus.import!(
        consent_statuses,
        on_duplicate_key_ignore: true
      )

      consent_statuses.select(&:persisted?).each(&:refresh!)
    end
  end

  def self.call(*args, **kwargs)
    new(*args, **kwargs).call
  end

  private_class_method :new

  private

  attr_reader :patient_sessions

  def build_patient_consent_statuses
    patient_sessions.flat_map do |patient_session|
      patient_session.programmes.map do |programme|
        Patient::ConsentStatus.new(
          patient_id: patient_session.patient_id,
          programme:
        )
      end
    end
  end
end
