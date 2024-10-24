# frozen_string_literal: true

class PatientSessionsController < ApplicationController
  before_action :set_patient_session
  before_action :set_session
  before_action :set_patient
  before_action :set_draft_vaccination_record
  before_action :set_section_and_tab
  before_action :set_back_link

  layout "three_quarters"

  def show
  end

  def log
  end

  def request_consent
    return unless @patient_session.no_consent?

    @session.programmes.each do |programme|
      ConsentNotification.create_and_send!(
        patient: @patient,
        programme:,
        session: @session,
        type: :request
      )
    end

    redirect_to session_patient_path(
                  @session,
                  @patient,
                  section: @section,
                  tab: @tab
                ),
                flash: {
                  success: "Consent request sent."
                }
  end

  private

  def set_patient_session
    @patient_session =
      policy_scope(PatientSession)
        .includes(:patient, :session, :vaccination_records)
        .preload(:consents, :triages)
        .find_by!(
          session_id: params.fetch(:session_id),
          patient_id: params.fetch(:id, params[:patient_id])
        )
  end

  def set_session
    @session = @patient_session.session
  end

  def set_patient
    @patient = @patient_session.patient
  end

  def set_draft_vaccination_record
    @draft_vaccination_record = @patient_session.draft_vaccination_record
  end

  def set_section_and_tab
    @section = params[:section]
    @tab = params[:tab]
  end

  def set_back_link
    @back_link =
      session_section_tab_path @session,
                               section: params[:section],
                               tab: params[:tab]
  end
end
