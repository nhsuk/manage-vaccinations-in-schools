# frozen_string_literal: true

module PatientSessionProgrammeConcern
  extend ActiveSupport::Concern

  included do
    before_action :set_session
    before_action :set_patient
    before_action :set_patient_session
    before_action :set_programme
  end

  def set_session
    @session =
      policy_scope(Session).includes(:location, :programmes).find_by!(
        slug: params.fetch(:session_slug, params[:slug])
      )
  end

  def set_patient
    @patient =
      policy_scope(Patient).includes(parent_relationships: :parent).find(
        params.fetch(:patient_id, params[:id])
      )
  end

  def set_patient_session
    @patient_session =
      PatientSession.find_by!(patient_id: @patient.id, session_id: @session.id)

    # Assigned to already loaded objects
    @patient_session.patient = @patient
    @patient_session.session = @session
  end

  def set_programme
    return unless params.key?(:programme_type)

    @programme =
      @patient_session.programmes.find do |programme|
        programme.type == params[:programme_type]
      end

    raise ActiveRecord::RecordNotFound if @programme.nil?
  end
end
