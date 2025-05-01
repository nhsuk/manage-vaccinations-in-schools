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

      school_moves.each do |school_move|
        school_move.create_log_entry!(user:)
        if school_move.persisted?
          SchoolMove.where(patient: school_move.patient).destroy_all
        end
      end
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
end
