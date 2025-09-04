# frozen_string_literal: true

class Sessions::InviteToClinicController < ApplicationController
  before_action :set_session
  before_action :set_generic_clinic_session
  before_action :set_patients_to_invite
  before_action :set_invitations_to_send

  skip_after_action :verify_policy_scoped

  def edit
    @initial_invitations = @session.school?
  end

  def update
    if @session.school?
      factory.create_patient_sessions!

      flash[
        :success
      ] = "#{I18n.t("children", count: @invitations_to_send)} invited to the clinic"
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

  def set_patients_to_invite
    @patients_to_invite =
      if @session.school?
        factory.patient_sessions_to_create.map(&:patient)
      else
        session_date = @generic_clinic_session.next_date(include_today: true)
        SendClinicSubsequentInvitationsJob.new.patients(@session, session_date:)
      end
  end

  def set_invitations_to_send
    @invitations_to_send = @patients_to_invite.length
  end

  def factory
    @factory ||=
      if @session.school?
        ClinicPatientSessionsFactory.new(
          school_session: @session,
          generic_clinic_session: @generic_clinic_session
        )
      end
  end
end
