# frozen_string_literal: true

class Sessions::InviteToClinicController < ApplicationController
  before_action :set_session
  before_action :set_generic_clinic_session
  before_action :set_invitations_to_send

  skip_after_action :verify_policy_scoped

  def edit
    @initial_invitations = @session.school?
  end

  def update
    if @session.school?
      SendClinicInitialInvitationsJob.perform_later(
        @generic_clinic_session,
        school: @session.location,
        programmes: @session.programmes.to_a
      )
      flash[
        :success
      ] = "Clinic invitations sent for #{I18n.t("children", count: @invitations_to_send)}"
    else
      SendClinicSubsequentInvitationsJob.perform_later(@session)
      flash[
        :success
      ] = "Booking reminders sent for #{I18n.t("children", count: @invitations_to_send)}"
    end

    redirect_to session_path(@session)
  end

  private

  def set_session
    @session =
      authorize Session.includes(:programmes).find_by!(
                  slug: params[:session_slug]
                )

    render status: :not_found unless @session.can_send_clinic_invitations?
  end

  def set_generic_clinic_session
    @generic_clinic_session =
      (
        if @session.clinic?
          @session
        else
          @session.organisation.generic_clinic_session(
            academic_year: @session.academic_year
          )
        end
      )
  end

  def set_invitations_to_send
    session_date = @generic_clinic_session.next_date(include_today: true)

    @invitations_to_send =
      if @session.school?
        SendClinicInitialInvitationsJob
          .new
          .patient_sessions(
            @generic_clinic_session,
            school: @session.location,
            programmes: @session.programmes.to_a,
            session_date:
          )
          .length
      else
        SendClinicSubsequentInvitationsJob
          .new
          .patient_sessions(@session, session_date:)
          .length
      end
  end
end
