# frozen_string_literal: true

class Sessions::InviteToClinicController < ApplicationController
  before_action :set_session
  before_action :set_generic_clinic_session
  before_action :set_patient_sessions_to_invite
  before_action :set_invitations_to_send

  skip_after_action :verify_policy_scoped

  def edit
    @initial_invitations = @session.school?
  end

  def update
    if @session.school?
      PatientSession.import!(
        @patient_sessions_to_invite,
        on_duplicate_key_ignore: true
      )

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
      if @session.clinic?
        @session
      else
        @session.team.generic_clinic_session(
          academic_year: @session.academic_year
        )
      end
  end

  def set_patient_sessions_to_invite
    session_date = @generic_clinic_session.next_date(include_today: true)

    if @session.school?
      patient_sessions_in_school = @session.patient_sessions.includes(:patient)

      patient_sessions_in_clinic =
        patient_sessions_in_school.map do |patient_session|
          PatientSession.find_or_initialize_by(
            patient: patient_session.patient,
            session: @generic_clinic_session
          )
        end

      programmes = @session.programmes.to_a

      @patient_sessions_to_invite =
        patient_sessions_in_clinic
          .reject { it.session_notifications.any? }
          .select do |patient_session|
            SendClinicInitialInvitationsJob.new.should_send_notification?(
              patient_session:,
              programmes:,
              session_date:
            )
          end
    else
      @patient_sessions_to_invite =
        SendClinicSubsequentInvitationsJob.new.patient_sessions(
          @session,
          session_date:
        )
    end
  end

  def set_invitations_to_send
    @invitations_to_send = @patient_sessions_to_invite.length
  end
end
