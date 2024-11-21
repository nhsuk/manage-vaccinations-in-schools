# frozen_string_literal: true

class DevController < ApplicationController
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
    organisation =
      Organisation.find_by!(ods_code: params[:organisation_ods_code])

    Organisation.with_advisory_lock("reset-organisation-#{organisation.id}") do
      CohortImport.where(organisation:).destroy_all
      ImmunisationImport.where(organisation:).destroy_all

      sessions = Session.where(organisation:)

      ClassImport.where(session: sessions).destroy_all
      SessionDate.where(session: sessions).destroy_all
      ConsentNotification.where(session: sessions).destroy_all
      SessionNotification.where(session: sessions).destroy_all

      patient_sessions = PatientSession.where(session: sessions)
      GillickAssessment.where(patient_session: patient_sessions).destroy_all
      VaccinationRecord.where(patient_session: patient_sessions).destroy_all
      patient_sessions.destroy_all

      sessions.destroy_all

      patients = Patient.joins(:cohort).where(cohorts: { organisation: })

      NotifyLogEntry.where(patient: patients).destroy_all

      ConsentForm.where(organisation:).destroy_all
      Consent.where(organisation:).destroy_all
      Triage.where(organisation:).destroy_all

      patients.destroy_all

      Cohort.where(organisation:).destroy_all

      UnscheduledSessionsFactory.new.call
    end

    head :ok
  end

  def random_consent_form
    Faker::Config.locale = "en-GB"
    @session = Session.find(params[:session_id])
    programme = @session.programmes.first
    @vaccine = programme.vaccines.first
    @consent_form =
      FactoryBot.build(:consent_form, :draft, programme:, session: @session)
    @consent_form.health_answers = @vaccine.health_questions.to_health_answers
    @consent_form.save!
    @consent_form.each_health_answer do |health_answer|
      health_answer.response = "no"
    end
    @consent_form.save!
    session[:consent_form_id] = @consent_form.id
    redirect_to confirm_parent_interface_consent_form_path(@consent_form)
  end

  private

  def ensure_dev_env_or_dev_tools_enabled
    unless Rails.env.development? || Rails.env.test? ||
             Flipper.enabled?(:dev_tools)
      raise "Not in development environment"
    end
  end
end
