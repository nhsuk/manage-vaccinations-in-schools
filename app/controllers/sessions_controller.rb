# frozen_string_literal: true

require "pagy/extras/array"

class SessionsController < ApplicationController
  include SessionSearchFormConcern

  before_action :set_session_search_form, only: :index
  before_action :set_session, except: :index

  def index
    @programmes = current_user.selected_organisation.programmes

    scope =
      policy_scope(Session).for_current_academic_year.includes(
        :location,
        :programmes,
        :session_dates
      )

    sessions = @form.apply(scope)

    @patient_count_by_session_id =
      PatientSession
        .where(session_id: sessions.map(&:id))
        .group(:session_id)
        .count

    @pagy, @sessions = pagy_array(sessions)

    render layout: "full"
  end

  def show
    respond_to do |format|
      format.html { render layout: "full" }

      format.xlsx do
        filename =
          if @session.location.urn.present?
            "#{@session.location.name} (#{@session.location.urn})"
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
  end

  def make_in_progress
    @session.session_dates.find_or_create_by!(value: Date.current)

    redirect_to session_path, flash: { success: "Session is now in progress" }
  end

  private

  def set_session
    @session = authorize policy_scope(Session).find_by!(slug: params[:slug])
  end
end
