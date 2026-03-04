# frozen_string_literal: true

class SchoolsController < ApplicationController
  include LocationSearchFormConcern

  before_action :set_location_search_form

  layout "full"

  def index
    authorize Location, policy_class: SchoolPolicy

    locations =
      @form.apply(
        policy_scope(Location).school.or(policy_scope(Location).generic_clinic)
      )

    @pagy, @locations = pagy(locations)

    @patient_count_by_school_id =
      Patient
        .joins(:patient_locations)
        .where(
          patient_locations: {
            location: @locations,
            academic_year: AcademicYear.pending
          }
        )
        .distinct
        .group(:school_id)
        .count

    @next_session_date_by_location_id =
      policy_scope(Session)
        .joins(:team_location)
        .joins("CROSS JOIN unnest(dates) date")
        .group("team_location.location_id")
        .where("date >= ?", Date.current)
        .minimum(:date)
  end
end
