# frozen_string_literal: true

class DevController < ApplicationController
  include ActionController::Live

  skip_before_action :authenticate_user!
  skip_before_action :store_user_location!
  skip_after_action :verify_policy_scoped

  before_action :ensure_dev_env_or_dev_tools_enabled

  def reset
    session.delete :user_return_to
    Rake::Task.clear
    Rails.application.load_tasks

    Organisation.with_advisory_lock("reset") do
      Rake::Task["db:seed:replant"].invoke
    end

    redirect_to root_path
  end

  def reset_organisation
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"

    organisation =
      Organisation.find_by!(ods_code: params[:organisation_ods_code])

    @start_time = Time.zone.now

    Organisation.with_advisory_lock("reset-organisation-#{organisation.id}") do
      log_destroy(CohortImport.where(organisation:))
      log_destroy(ImmunisationImport.where(organisation:))

      sessions = Session.where(organisation:)

      log_destroy(ClassImport.where(session: sessions))
      log_destroy(SessionDate.where(session: sessions))

      log_destroy(ConsentNotification.where(session: sessions))
      log_destroy(SessionNotification.where(session: sessions))
      log_destroy(VaccinationRecord.where(session: sessions))

      patient_sessions = PatientSession.where(session: sessions)
      log_destroy(GillickAssessment.where(patient_session: patient_sessions))
      log_destroy(PreScreening.where(patient_session: patient_sessions))
      patient_sessions.in_batches { log_destroy(it) }

      log_destroy(sessions)

      patients = organisation.patients

      log_destroy(SchoolMove.where(patient: patients))
      log_destroy(SchoolMove.where(organisation:))
      log_destroy(SchoolMoveLogEntry.where(patient: patients))
      log_destroy(AccessLogEntry.where(patient: patients))
      log_destroy(NotifyLogEntry.where(patient: patients))
      # In local dev we can end up with NotifyLogEntries without a patient
      log_destroy(NotifyLogEntry.where(patient_id: nil))
      log_destroy(VaccinationRecord.where(patient: patients))

      log_destroy(ConsentForm.where(organisation:))
      log_destroy(Consent.where(organisation:))
      log_destroy(Triage.where(organisation:))

      patients.includes(:parents).in_batches { log_destroy(it) }

      batches = Batch.where(organisation:)
      log_destroy(VaccinationRecord.where(batch: batches))
      log_destroy(batches)

      log_destroy(
        VaccinationRecord.where(performed_ods_code: organisation.ods_code)
      )

      UnscheduledSessionsFactory.new.call
    end

    response.stream.write "Done"
  ensure
    response.stream.close
  end

  def random_consent_form
    Faker::Config.locale = "en-GB"

    session = Session.includes(programmes: :vaccines).find(params[:session_id])

    attributes =
      if ActiveModel::Type::Boolean.new.cast(params[:parent_phone])
        {}
      else
        { parent_phone: nil }
      end

    consent_form =
      FactoryBot.create(:consent_form, :draft, session:, **attributes)

    consent_form.seed_health_questions
    consent_form.each_health_answer do |health_answer|
      health_answer.response = "no"
    end
    consent_form.save!

    request.session[:consent_form_id] = consent_form.id
    redirect_to confirm_parent_interface_consent_form_path(consent_form)
  end

  private

  def ensure_dev_env_or_dev_tools_enabled
    unless Rails.env.local? || Flipper.enabled?(:dev_tools)
      raise "Not in development environment"
    end
  end

  def log_destroy(query)
    where_clause = query.where_clause
    @log_time ||= Time.zone.now
    query.destroy_all
    response.stream.write(
      "#{query.model.name}.where(#{where_clause.to_h}) reset: #{Time.zone.now - @log_time}s\n"
    )
    @log_time = Time.zone.now
  end
end
