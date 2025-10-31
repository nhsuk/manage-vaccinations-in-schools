# frozen_string_literal: true

class API::Testing::TeamsController < API::Testing::BaseController
  include ActionController::Live

  def destroy
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"

    keep_itself = ActiveModel::Type::Boolean.new.cast(params[:keep_itself])

    team = Team.find_by!(workgroup: params[:workgroup])

    @start_time = Time.zone.now

    log_destroy(CohortImport.where(team:))
    log_destroy(ImmunisationImport.where(team:))
    log_destroy(ClassImport.where(team:))

    log_destroy(SchoolMove.where(team:))
    log_destroy(Consent.where(team:))
    log_destroy(ArchiveReason.where(team:))
    log_destroy(Triage.where(team:))

    log_destroy(
      NotifyLogEntry.joins(:consent_form).where(consent_form: { team: })
    )
    log_destroy(ConsentForm.where(team:))

    log_destroy(ConsentNotification.joins(:session).where(session: { team: }))
    log_destroy(SessionNotification.joins(:session).where(session: { team: }))
    log_destroy(VaccinationRecord.joins(:session).where(session: { team: }))

    patient_ids = team.patients.pluck(:id)

    log_destroy(
      PatientLocation.joins(location: :subteam).where(subteam: { team: })
    )

    log_destroy(AccessLogEntry.where(patient_id: patient_ids))
    log_destroy(ArchiveReason.where(patient_id: patient_ids))
    log_destroy(AttendanceRecord.where(patient_id: patient_ids))
    log_destroy(ConsentNotification.where(patient_id: patient_ids))
    log_destroy(GillickAssessment.where(patient_id: patient_ids))
    log_destroy(Note.where(patient_id: patient_ids))
    # In local dev we can end up with NotifyLogEntries without a patient
    log_destroy(NotifyLogEntry.where(patient_id: nil))
    log_destroy(NotifyLogEntry.where(patient_id: patient_ids))
    log_destroy(PatientChangeset.where(patient_id: patient_ids))
    log_destroy(PatientLocation.where(patient_id: patient_ids))
    log_destroy(PatientSpecificDirection.where(patient_id: patient_ids))
    log_destroy(PDSSearchResult.where(patient_id: patient_ids))
    log_destroy(PreScreening.where(patient_id: patient_ids))
    log_destroy(SchoolMove.where(patient_id: patient_ids))
    log_destroy(SchoolMoveLogEntry.where(patient_id: patient_ids))
    log_destroy(VaccinationRecord.where(patient_id: patient_ids))

    log_destroy(SessionDate.joins(:session).where(session: { team: }))

    log_destroy(ParentRelationship.where(patient_id: patient_ids))
    log_destroy(Patient.where(id: patient_ids))
    log_destroy(Parent.where.missing(:parent_relationships))

    log_destroy(VaccinationRecord.joins(:batch).where(batch: { team: }))
    log_destroy(Batch.where(team:))

    log_destroy(
      VaccinationRecord.where(performed_ods_code: team.organisation.ods_code)
    )

    TeamCachedCounts.new(team).reset_all!

    unless keep_itself
      log_destroy(Session.where(team:))

      log_destroy(
        Location.generic_clinic.joins(:subteam).where(subteam: { team: })
      )
      Location
        .joins(:subteam)
        .where(subteam: { team: })
        .update_all(subteam_id: nil)

      log_destroy(Subteam.where(team:))

      log_destroy(Team.where(id: team.id))
    end

    response.stream.write "Done"
  rescue StandardError => e
    response.stream.write "Error: #{e.message}\n"
  ensure
    response.stream.close
  end

  private

  def log_destroy(query)
    where_clause = query.where_clause
    @log_time ||= Time.zone.now
    query.delete_all
    response.stream.write(
      "#{query.model.name}.where(#{where_clause.to_h}): #{Time.zone.now - @log_time}s\n"
    )
    @log_time = Time.zone.now
  end
end
