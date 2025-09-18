# frozen_string_literal: true

class API::Testing::TeamsController < API::Testing::BaseController
  include ActionController::Live

  def destroy
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"

    keep_itself = ActiveModel::Type::Boolean.new.cast(params[:keep_itself])

    team = Team.find_by!(workgroup: params[:workgroup])

    @start_time = Time.zone.now

    Team.with_advisory_lock("reset-team-#{team.id}") do
      ActiveRecord::Base.transaction do
        log_destroy(CohortImport.where(team:))
        log_destroy(ImmunisationImport.where(team:))
        log_destroy(ClassImport.where(team:))

        sessions = Session.where(team:)

        log_destroy(ConsentNotification.where(session: sessions))
        log_destroy(SessionNotification.where(session: sessions))
        log_destroy(VaccinationRecord.where(session: sessions))

        patient_ids = team.patients.pluck(:id)
        consent_form_ids = team.consent_forms.pluck(:id)

        log_destroy(
          PatientLocation.where(location_id: sessions.select(:location_id))
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
        log_destroy(NotifyLogEntry.where(consent_form_id: consent_form_ids))
        log_destroy(PatientChangeset.where(patient_id: patient_ids))
        log_destroy(PatientLocation.where(patient_id: patient_ids))
        log_destroy(PatientSpecificDirection.where(patient_id: patient_ids))
        log_destroy(PDSSearchResult.where(patient_id: patient_ids))
        log_destroy(PreScreening.where(patient_id: patient_ids))
        log_destroy(SchoolMove.where(patient_id: patient_ids))
        log_destroy(SchoolMove.where(team:))
        log_destroy(SchoolMoveLogEntry.where(patient_id: patient_ids))
        log_destroy(VaccinationRecord.where(patient_id: patient_ids))

        log_destroy(ConsentForm.where(id: consent_form_ids))
        log_destroy(SessionDate.where(session: sessions))

        log_destroy(ArchiveReason.where(team:))
        log_destroy(Consent.where(team:))
        log_destroy(Triage.where(team:))

        Patient
          .where(id: patient_ids)
          .includes(:parents)
          .in_batches { log_destroy(it) }

        batches = Batch.where(team:)
        log_destroy(VaccinationRecord.where(batch: batches))
        log_destroy(batches)

        log_destroy(
          VaccinationRecord.where(
            performed_ods_code: team.organisation.ods_code
          )
        )

        unless keep_itself
          log_destroy(SessionProgramme.where(session: sessions))
          log_destroy(sessions)

          subteams = Subteam.where(team:)
          log_destroy(Location.generic_clinic.where(subteam: subteams))
          Location.where(subteam: subteams).update_all(subteam_id: nil)
          log_destroy(subteams)

          log_destroy(TeamProgramme.where(team:))
          log_destroy(Team.where(id: team.id))
        end
      end
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
    query.destroy_all
    response.stream.write(
      "#{query.model.name}.where(#{where_clause.to_h}): #{Time.zone.now - @log_time}s\n"
    )
    @log_time = Time.zone.now
  end
end
