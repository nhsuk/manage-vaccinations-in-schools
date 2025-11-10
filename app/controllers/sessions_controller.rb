# frozen_string_literal: true

class SessionsController < ApplicationController
  include SessionSearchFormConcern

  before_action :set_session_search_form, only: :index
  before_action :set_session, except: :index

  def index
    @programmes = current_user.selected_team.programmes

    scope =
      policy_scope(Session).includes(:location, :programmes, :session_dates)

    sessions = @form.apply(scope)

    @pagy, @sessions = pagy_array(sessions)

    @patient_count_by_session_id = patient_counts_for_sessions(@sessions)

    render layout: "full"
  end

  def show
    respond_to do |format|
      format.html { render layout: "full" }

      format.xlsx do
        filename =
          if (urn_and_site = @session.location.urn_and_site).present?
            "#{@session.location.name} (#{urn_and_site})"
          else
            @session.location.name
          end

        send_data(
          Reports::OfflineSessionExporter.call(@session),
          filename:
            "#{filename} - exported on #{Date.current.to_fs(:long)}.xlsx",
          disposition: "attachment"
        )
      end
    end
  end

  def edit
    DraftSession.new(request_session: session, current_user:).read_from!(
      @session
    )

    redirect_to draft_session_path("confirm")
  end

  def import
    draft_import = DraftImport.new(request_session: session, current_user:)

    draft_import.clear_attributes
    draft_import.update!(location: @session.location, type: "class")

    steps = draft_import.wizard_steps
    steps.delete(:type)
    steps.delete(:location)

    redirect_to draft_import_path(I18n.t(steps.first, scope: :wicked))
  end

  def make_in_progress
    valid_date_range = @session.academic_year.to_academic_year_date_range

    date = Date.current

    if date.in?(valid_date_range)
      @session.session_dates.find_or_create_by!(value: date)
      redirect_to session_path, flash: { success: "Session is now in progress" }
    else
      redirect_to session_path,
                  flash: {
                    error: "Today is not a valid date for this session"
                  }
    end
  end

  private

  def set_session
    @session = authorize policy_scope(Session).find_by!(slug: params[:slug])
  end

  def patient_counts_for_sessions(sessions)
    Patient
      .joins_sessions
      .in_eligible_year_group_for_session_programme
      .where("sessions.id = ANY(ARRAY[?]::bigint[])", sessions.map(&:id))
      .group("sessions.id")
      .count("DISTINCT patients.id")
  end
end
