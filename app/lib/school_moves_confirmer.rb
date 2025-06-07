# frozen_string_literal: true

class SchoolMovesConfirmer
  def initialize(school_moves, user: nil)
    @school_moves = school_moves
    @user = user
  end

  def call
    ActiveRecord::Base.transaction do
      update_patients!
      update_sessions!
      create_log_entries!
      destroy_school_moves!
    end
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :school_moves, :user

  def update_patients!
    patients_to_import =
      school_moves.filter_map do |school_move|
        patient = school_move.patient

        patient.home_educated = school_move.home_educated
        patient.school = school_move.school

        patient if patient.changed?
      end

    Patient.import!(
      patients_to_import,
      on_duplicate_key_update: {
        conflict_target: [:id],
        columns: %i[home_educated school_id]
      }
    )
  end

  def update_sessions!
    patients = school_moves.map(&:patient)

    PatientSession.where(patient: patients).destroy_all_if_safe

    patient_sessions_to_import =
      school_moves.flat_map do |school_move|
        school_move.sessions.map do |session|
          [school_move.patient.id, session.id]
        end
      end

    PatientSession.import!(
      %i[patient_id session_id],
      patient_sessions_to_import,
      on_duplicate_key_ignore: :all
    )

    StatusUpdater.call(patient: patients)
  end

  def create_log_entries!
    log_entries =
      school_moves.map { |school_move| school_move.to_log_entry(user:) }

    SchoolMoveLogEntry.import!(log_entries)
  end

  def destroy_school_moves!
    patients = school_moves.select(&:persisted?).map(&:patient)
    SchoolMove.where(patient: patients).destroy_all
  end
end
