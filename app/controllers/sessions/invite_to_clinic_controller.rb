# frozen_string_literal: true

class Sessions::InviteToClinicController < Sessions::BaseController
  before_action :check_can_send_clinic_invitations
  before_action :set_generic_clinic_session
  before_action :set_patients_to_invite
  before_action :set_invitations_to_send

  skip_after_action :verify_policy_scoped

  def edit
    @initial_invitations = @session.school?
  end

  def update
    factory.create_patient_locations! if @session.school?

    @patients_to_invite.each do |patient|
      patient.notifier.send_clinic_invitation(
        @session.programmes_for(patient:),
        team: @session.team,
        academic_year: @session.academic_year,
        sent_by: current_user
      )
    end

    children_count = I18n.t("children", count: @invitations_to_send)

    flash[:success] = if @session.school?
      "#{children_count} invited to the clinic"
    else
      "Booking reminders sent for #{children_count}"
    end

    redirect_to session_path(@session)
  end

  private

  def check_can_send_clinic_invitations
    render status: :not_found unless @session.can_send_clinic_invitations?
  end

  def set_generic_clinic_session
    @generic_clinic_session =
      if @session.clinic?
        @session
      else
        GenericClinicSessionFinder.call(
          team: @session.team,
          academic_year: @session.academic_year,
          programmes: @session.programmes
        )
      end
  end

  def set_patients_to_invite
    @patients_to_invite =
      if @session.school?
        factory.patient_locations_to_create.map(&:patient)
      else
        @session.patients
      end
  end

  def set_invitations_to_send
    @invitations_to_send = @patients_to_invite.length
  end

  def factory
    @factory ||=
      if @session.school?
        ClinicPatientLocationsFactory.new(school_session: @session)
      end
  end
end
