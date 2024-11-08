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
      cohort_imports = CohortImport.where(organisation:)
      cohort_imports.find_each do |cohort_import|
        cohort_import.parent_relationships.clear
        cohort_import.patients.clear
        cohort_import.parents.clear

        cohort_import.destroy!
      end

      immunisation_imports = ImmunisationImport.where(organisation:)
      immunisation_imports.find_each do |immunisation_import|
        immunisation_import.batches.clear
        immunisation_import.patient_sessions.clear
        immunisation_import.patients.clear
        immunisation_import.sessions.clear
        immunisation_import.vaccination_records.clear

        immunisation_import.destroy!
      end

      organisation_sessions = Session.where(organisation:)

      ClassImport.where(session: organisation_sessions).destroy_all

      patient_sessions = PatientSession.where(session: organisation_sessions)
      patient_sessions.each do |patient_session|
        patient_session.vaccination_records.destroy_all
        patient_session.patient.triages.destroy_all
        GillickAssessment.where(patient_session:).destroy_all
        patient_session.destroy!
      end

      organisation_sessions.each do |organisation_session|
        organisation_session.session_dates.destroy_all
        organisation_session.destroy!
      end

      ConsentForm.where(organisation:).delete_all
      Consent.where(organisation:).delete_all

      Patient
        .joins(:cohort)
        .where(cohorts: { organisation: })
        .distinct
        .destroy_all
      Cohort.where(organisation:).delete_all

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
