# frozen_string_literal: true

class SessionsController < ApplicationController
  before_action :set_session,
                except: %i[index scheduled unscheduled completed closed]

  def index
    @sessions = sessions_scope.today.sort

    render layout: "full"
  end

  def scheduled
    @sessions = sessions_scope.scheduled.sort

    render layout: "full"
  end

  def unscheduled
    @sessions = sessions_scope.unscheduled.sort

    render layout: "full"
  end

  def completed
    @sessions = sessions_scope.completed.sort

    render layout: "full"
  end

  def closed
    @sessions = sessions_scope.closed.sort

    render layout: "full"
  end

  def show
    respond_to do |format|
      format.html do
        patient_sessions =
          @session.patient_sessions.preload_for_state.strict_loading

        @stats = PatientSessionStats.new(patient_sessions)

        render layout: "full"
      end

      format.xlsx do
        filename =
          if @session.location.urn.present?
            "#{@session.location.name} (#{@session.location.urn})"
          else
            @session.location.name
          end

        send_data(
          SessionXlsxExporter.call(@session),
          filename:
            "#{filename} - exported on #{Date.current.to_fs(:long)}.xlsx",
          disposition: "attachment"
        )
      end
    end
  end

  def edit
  end

  def edit_close
    @unvaccinated_patients_count = @session.unvaccinated_patients.length

    render :close
  end

  def update_close
    @session.close!

    redirect_to session_path(@session), flash: { success: "Session closed." }
  end

  def consent_form
    programme = @session.programmes.first # TODO: handle multiple programmes

    send_file(
      "public/consent_forms/#{programme.type}.pdf",
      filename: "#{programme.name} Consent Form.pdf",
      disposition: "attachment"
    )
  end

  def make_in_progress
    @session.session_dates.find_or_create_by!(value: Date.current)

    redirect_to session_path, flash: { success: "Session is now in progress" }
  end

  private

  delegate :organisation, to: :current_user

  def set_session
    @session = sessions_scope.find_by!(slug: params[:slug])
  end

  def sessions_scope
    policy_scope(Session).includes(
      :location,
      :programmes,
      :session_dates,
      organisation: :programmes
    ).strict_loading
  end
end
