# frozen_string_literal: true

class DevController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :store_user_location!
  skip_after_action :verify_policy_scoped

  before_action :ensure_dev_env

  def reset
    session.delete :user_return_to
    Rake::Task.clear
    Rails.application.load_tasks
    Rake::Task["db:seed:replant"].invoke

    redirect_to root_path
  end

  def reset_team
    team = Team.find_by(ods_code: params[:team_ods_code])

    cohort_imports = CohortImport.where(team:)
    cohort_imports.find_each do |cohort_import|
      cohort_import.parent_relationships.clear
      cohort_import.patients.clear
      cohort_import.parents.clear

      cohort_import.destroy!
    end

    immunisation_imports = ImmunisationImport.where(team:)
    immunisation_imports.find_each do |immunisation_import|
      immunisation_import.batches.clear
      immunisation_import.locations.clear
      immunisation_import.patient_sessions.clear
      immunisation_import.patients.clear
      immunisation_import.sessions.clear
      immunisation_import.vaccination_records.clear

      immunisation_import.destroy!
    end

    team_sessions = Session.where(team:)

    patient_sessions = PatientSession.where(session: team_sessions)
    patient_sessions.each do |patient_session|
      patient_session.vaccination_records.destroy_all
      patient_session.triage.destroy_all
      patient_session.destroy!
    end

    team_sessions.each do |team_session|
      team_session.consent_forms.destroy_all
      team_session.dates.destroy_all
      team_session.destroy!
    end

    Patient
      .joins(:cohort)
      .where(cohorts: { team: })
      .distinct
      .find_each do |patient|
        parent_ids = patient.parent_ids
        patient.parents.clear
        parent_ids.each { |parent_id| Parent.find(parent_id).destroy }

        patient.save!
        patient.destroy!
      end

    Cohort.where(team:).delete_all

    head :ok
  end

  def random_consent_form
    Faker::Config.locale = "en-GB"
    @session = Session.find(params.fetch(:session_id))
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
    redirect_to session_parent_interface_consent_form_confirm_path(
                  @session,
                  @consent_form
                )
  end

  private

  def ensure_dev_env
    unless Rails.env.development? || Rails.env.test?
      raise "Not in development environment"
    end
  end
end
