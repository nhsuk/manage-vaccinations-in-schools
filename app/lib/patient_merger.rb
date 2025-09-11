# frozen_string_literal: true

class PatientMerger
  def initialize(to_keep:, to_destroy:)
    @patient_to_keep = to_keep
    @patient_to_destroy = to_destroy
  end

  def call
    vaccination_record_ids = []

    ActiveRecord::Base.transaction do
      patient_to_destroy.access_log_entries.update_all(
        patient_id: patient_to_keep.id
      )

      patient_to_keep.archive_reasons.find_each do |archive_reason|
        unless patient_to_destroy.archive_reasons.exists?(
                 team_id: archive_reason.team_id
               )
          archive_reason.destroy!
        end
      end

      patient_to_destroy.archive_reasons.destroy_all

      patient_to_destroy.consent_notifications.update_all(
        patient_id: patient_to_keep.id
      )
      patient_to_destroy.consents.update_all(patient_id: patient_to_keep.id)

      patient_to_destroy.notes.update_all(patient_id: patient_to_keep.id)

      patient_to_destroy.notify_log_entries.update_all(
        patient_id: patient_to_keep.id
      )

      patient_to_destroy.gillick_assessments.update_all(
        patient_id: patient_to_keep.id
      )

      patient_to_destroy.pds_search_results.update_all(
        patient_id: patient_to_keep.id
      )

      patient_to_destroy.pre_screenings.update_all(
        patient_id: patient_to_keep.id
      )

      patient_to_destroy.school_moves.find_each do |school_move|
        if patient_to_keep.school_moves.exists?(
             home_educated: school_move.home_educated,
             team_id: school_move.team_id,
             school_id: school_move.school_id
           )
          school_move.destroy!
        else
          school_move.update!(patient: patient_to_keep)
        end
      end

      patient_to_destroy.school_move_log_entries.update_all(
        patient_id: patient_to_keep.id
      )

      patient_to_destroy.session_attendances.update_all(
        patient_id: patient_to_keep.id
      )

      patient_to_destroy.session_notifications.update_all(
        patient_id: patient_to_keep.id
      )

      patient_to_destroy.triages.update_all(patient_id: patient_to_keep.id)

      vaccination_record_ids =
        patient_to_destroy.vaccination_records.with_discarded.ids
      patient_to_destroy.vaccination_records.with_discarded.update_all(
        patient_id: patient_to_keep.id
      )

      patient_to_destroy.parent_relationships.find_each do |relationship|
        if patient_to_keep.parent_relationships.exists?(
             parent_id: relationship.parent_id
           )
          relationship.destroy!
        else
          relationship.update!(patient_id: patient_to_keep.id)
        end
      end

      patient_to_destroy.patient_sessions.each do |patient_session|
        if patient_to_keep.patient_sessions.exists?(
             session_id: patient_session.session_id
           )
          next
        end
        patient_session.update!(patient: patient_to_keep)
      end

      PatientSession.where(patient: patient_to_destroy).destroy_all

      patient_to_destroy.changesets.update_all(patient_id: nil)

      patient_to_destroy.class_imports.each do |import|
        unless patient_to_keep.class_imports.include?(import)
          patient_to_keep.class_imports << import
        end
      end

      patient_to_destroy.cohort_imports.each do |import|
        unless patient_to_keep.cohort_imports.include?(import)
          patient_to_keep.cohort_imports << import
        end
      end

      patient_to_destroy.immunisation_imports.each do |import|
        unless patient_to_keep.immunisation_imports.include?(import)
          patient_to_keep.immunisation_imports << import
        end
      end

      patient_to_destroy.class_imports.clear
      patient_to_destroy.cohort_imports.clear
      patient_to_destroy.immunisation_imports.clear

      patient_to_destroy.reload.destroy!

      StatusUpdater.call(patient: patient_to_keep)
    end

    VaccinationRecord.where(
      id: vaccination_record_ids
    ).sync_all_to_nhs_immunisations_api
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :patient_to_keep, :patient_to_destroy
end
