# frozen_string_literal: true

class Sessions::InviteToClinicController < Sessions::BaseController
  before_action :authorize_session
  before_action :set_patients_to_invite
  before_action :set_invitations_to_send

  def edit
  end

  def update
    factory.create_patient_locations!

    @patients_to_invite.each do |patient|
      patient.notifier.send_clinic_invitation(
        @session.programmes_for(patient:),
        team: @session.team,
        academic_year: @session.academic_year,
        sent_by: current_user
      )
    end

    flash[
      :success
    ] = "#{I18n.t("children", count: @invitations_to_send)} invited to the clinic"

    redirect_to session_path(@session)
  end

  private

  def authorize_session
    authorize @session, :invite_to_clinic?
  end

  def set_patients_to_invite
    @patients_to_invite = factory.patient_locations_to_create.map(&:patient)
  end

  def set_invitations_to_send
    @invitations_to_send = @patients_to_invite.length
  end

  def factory
    @factory ||= ClinicPatientLocationsFactory.new(school_session: @session)
  end
end
