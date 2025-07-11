# frozen_string_literal: true

class API::OrganisationsController < API::BaseController
  include ActionController::Live

  def destroy
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"

    keep_itself = ActiveModel::Type::Boolean.new.cast(params[:keep_itself])
    organisation = Organisation.find_by!(ods_code: params[:ods_code])

    @start_time = Time.zone.now

    Organisation.with_advisory_lock("reset-organisation-#{organisation.id}") do
      ActiveRecord::Base.transaction do
        log_destroy(CohortImport.where(organisation:))
        log_destroy(ImmunisationImport.where(organisation:))

        sessions = Session.where(organisation:)

        log_destroy(ClassImport.where(session: sessions))

        log_destroy(ConsentNotification.where(session: sessions))
        log_destroy(SessionNotification.where(session: sessions))
        log_destroy(VaccinationRecord.where(session: sessions))

        patient_ids = organisation.patients.pluck(:id)

        patient_sessions = PatientSession.where(session: sessions)
        log_destroy(GillickAssessment.where(patient_session: patient_sessions))
        log_destroy(PreScreening.where(patient_session: patient_sessions))
        patient_sessions.in_batches { log_destroy(it) }

        log_destroy(SessionDate.where(session: sessions))

        log_destroy(SchoolMove.where(patient_id: patient_ids))
        log_destroy(SchoolMove.where(organisation:))
        log_destroy(SchoolMoveLogEntry.where(patient_id: patient_ids))
        log_destroy(AccessLogEntry.where(patient_id: patient_ids))
        log_destroy(NotifyLogEntry.where(patient_id: patient_ids))
        # In local dev we can end up with NotifyLogEntries without a patient
        log_destroy(NotifyLogEntry.where(patient_id: nil))
        log_destroy(VaccinationRecord.where(patient_id: patient_ids))

        log_destroy(ConsentForm.where(organisation:))
        log_destroy(Consent.where(organisation:))
        log_destroy(Triage.where(organisation:))

        Patient
          .where(id: patient_ids)
          .includes(:parents)
          .in_batches { log_destroy(it) }

        batches = Batch.where(organisation:)
        log_destroy(VaccinationRecord.where(batch: batches))
        log_destroy(batches)

        log_destroy(
          VaccinationRecord.where(performed_ods_code: organisation.ods_code)
        )

        unless keep_itself
          log_destroy(SessionProgramme.where(session: sessions))
          log_destroy(sessions)

          teams = Team.where(organisation:)
          Location.where(team: teams).update_all(team_id: nil)

          log_destroy(teams)
          log_destroy(
            Location.generic_clinic.where(ods_code: organisation.ods_code)
          )

          log_destroy(OrganisationProgramme.where(organisation:))
          log_destroy(Organisation.where(id: organisation.id))
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
