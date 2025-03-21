# frozen_string_literal: true

class StatusUpdater
  def initialize(patient: nil, session: nil)
    scope = PatientSession

    scope = scope.where(patient:) if patient
    scope = scope.where(session:) if session

    @patient_sessions = scope
  end

  def call
    update_consent_statuses!
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :patient_sessions

  def update_consent_statuses!
    Patient::ConsentStatus.import!(
      %i[patient_id programme_id],
      patient_statuses_to_import,
      on_duplicate_key_ignore: true
    )

    Patient::ConsentStatus
      .where(patient: patient_sessions.select(:patient_id))
      .includes(:consents)
      .find_in_batches(batch_size: 10_000) do |batch|
        batch.each(&:assign_status)

        Patient::ConsentStatus.import!(
          batch,
          on_duplicate_key_update: {
            conflict_target: [:id],
            columns: %i[health_answers_require_follow_up status]
          }
        )
      end
  end

  def patient_statuses_to_import
    @patient_statuses_to_import ||=
      patient_sessions
        .joins(:patient)
        .pluck(:patient_id, :"patients.birth_academic_year")
        .uniq
        .flat_map do |patient_id, birth_academic_year|
          programme_ids_per_birth_academic_year
            .fetch(birth_academic_year, [])
            .map { [patient_id, it] }
        end
  end

  def programme_ids_per_birth_academic_year
    @programme_ids_per_birth_academic_year ||=
      Programme
        .all
        .each_with_object({}) do |programme, hash|
          programme.birth_academic_years.each do |year_group|
            hash[year_group] ||= []
            hash[year_group] << programme.id
          end
        end
  end
end
