# frozen_string_literal: true

class SchoolsController < ApplicationController
  include LocationSearchFormConcern
  include PatientSearchFormConcern

  before_action :set_location_search_form, only: :index
  before_action :set_location, except: :index
  before_action :set_programme_statuses,
                :set_patient_search_form,
                only: :patients

  layout "full"

  def index
    locations =
      @form.apply(
        policy_scope(Location).school.or(policy_scope(Location).generic_clinic)
      )

    @pagy, @locations = pagy(locations)

    @patient_count_by_school_id =
      Patient
        .joins(:patient_locations)
        .where(patient_locations: { location: @locations, academic_year: })
        .group(:school_id)
        .count

    @next_session_date_by_location_id =
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
    draft_import.update!(location: @location, type: "class")

    steps = draft_import.wizard_steps
    steps.delete(:type)
    steps.delete(:location)

    redirect_to draft_import_path(I18n.t(steps.first, scope: :wicked))
  end

  def patients
    scope =
      Patient
        .joins(:patient_locations)
        .where(patient_locations: { location: @location, academic_year: })
        .where(school_id: @location.school_id)

    patients = @form.apply(scope)

    @pagy, @patients = pagy(patients)
  end

  def sessions
    sessions =
      policy_scope(Session).for_academic_year(academic_year).for_location(
        @location
      )

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

  def academic_year = AcademicYear.pending

  def set_location
    urn_and_site = params[:school_urn_and_site]

    @location =
      if urn_and_site.in?([Location::URN_UNKNOWN, Location::URN_HOME_EDUCATED])
        policy_scope(Location).generic_clinic.sole
      else
        policy_scope(Location).school.find_by_urn_and_site!(
          params[:school_urn_and_site]
        )
      end
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
