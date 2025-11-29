# frozen_string_literal: true

class SchoolsController < ApplicationController
  include PatientSearchFormConcern
  include SchoolSearchFormConcern

  before_action :set_school_search_form, only: :index
  before_action :set_school, except: :index
  before_action :set_programme_statuses,
                :set_patient_search_form,
                only: :patients

  layout "full"

  def index
    schools = @form.apply(policy_scope(Location).school)

    @pagy, @schools = pagy(schools)

    @patient_count_by_school_id = policy_scope(Patient).group(:school_id).count

    @next_session_date_by_school_id =
      policy_scope(Session)
        .joins(:team_location)
        .joins("CROSS JOIN unnest(dates) date")
        .group("team_location.location_id")
        .where("date >= ?", Date.current)
        .minimum(:date)

    render layout: "full"
  end

  def import
    draft_import = DraftImport.new(request_session: session, current_user:)

    draft_import.clear_attributes
    draft_import.update!(location: @school, type: "class")

    steps = draft_import.wizard_steps
    steps.delete(:type)
    steps.delete(:location)

    redirect_to draft_import_path(I18n.t(steps.first, scope: :wicked))
  end

  def patients
    patients = @form.apply(policy_scope(Patient).where(school: @school))

    @pagy, @patients = pagy(patients)
  end

  def sessions
    sessions =
      policy_scope(Session).for_academic_year(
        AcademicYear.current
      ).for_location(@school)

    @patient_count_by_session_id =
      Patient
        .joins_sessions
        .joins_session_programme_year_groups
        .where("sessions.id = ANY(ARRAY[?]::bigint[])", sessions.pluck(:id))
        .group("sessions.id")
        .count("DISTINCT patients.id")

    @unscheduled_sessions = sessions.unscheduled
    @scheduled_sessions = sessions.scheduled
    @completed_sessions = sessions.completed
  end

  private

  def set_school
    @school =
      policy_scope(Location).school.find_by_urn_and_site!(
        params[:school_urn_and_site]
      )
  end

  def set_programme_statuses
    @programme_statuses =
      Patient::ProgrammeStatus.statuses.keys -
        %w[
          not_eligible
          needs_consent_request_not_scheduled
          needs_consent_request_scheduled
          needs_consent_request_failed
          needs_consent_follow_up_requested
        ]
  end
end
