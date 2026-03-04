# frozen_string_literal: true

class Schools::SessionsController < Schools::BaseController
  def index
    sessions =
      policy_scope(Session).for_academic_year(@academic_year).for_location(
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
end
