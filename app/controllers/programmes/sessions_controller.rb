# frozen_string_literal: true

require "pagy/extras/array"

class Programmes::SessionsController < Programmes::BaseController
  include SessionSearchFormConcern

  before_action :set_session_search_form

  def index
    scope =
      policy_scope(Session)
        .has_programmes([@programme])
        .where(academic_year: @academic_year)
        .includes(:location, :programmes, :session_dates)

    sessions = @form.apply(scope)

    @patient_count_by_session_id =
      PatientSession
        .where(session_id: sessions.map(&:id))
        .group(:session_id)
        .count

    @pagy, @sessions = pagy_array(sessions)

    render layout: "full"
  end
end
