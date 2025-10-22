# frozen_string_literal: true

class PatientSessions::BaseController < ApplicationController
  include PatientLoggingConcern
  before_action :set_session
  before_action :set_academic_year
  before_action :set_patient
  before_action :set_patient_location
  before_action :set_programme
  before_action :set_breadcrumb_item

  layout "three_quarters"

  private

  def set_session
    @session =
      policy_scope(Session).includes(
        :location,
        :location_programme_year_groups,
        :programmes
      ).find_by!(slug: params.fetch(:session_slug, params[:slug]))
  end

  def set_session_date
    @session_date = @session.session_dates.find_by!(value: Date.current)
  end

  def set_academic_year
    @academic_year = @session.academic_year
  end

  def set_patient
    @patient =
      policy_scope(Patient).includes(parent_relationships: :parent).find(
        params.fetch(:patient_id, params[:id])
      )
  end

  def set_patient_location
    @patient_location =
      PatientLocation.find_by!(
        patient: @patient,
        location: @session.location,
        academic_year: @session.academic_year
      )
  end

  def set_programme
    return unless params.key?(:programme_type) || params.key?(:type)

    @programme =
      @session
        .programmes_for(patient: @patient)
        .find do |programme|
          programme.type == params[:programme_type] ||
            programme.type == params[:type]
        end

    raise ActiveRecord::RecordNotFound if @programme.nil?
  end

  def set_breadcrumb_item
    return_to = params[:return_to]
    return nil if return_to.blank?

    known_return_to = %w[patients consent triage register record]
    return unless return_to.in?(known_return_to)

    @breadcrumb_item = {
      text: t(return_to, scope: %i[sessions tabs]),
      href: send(:"session_#{return_to}_path")
    }
  end

  def record_access_log_entry
    @patient.access_log_entries.create!(
      user: current_user,
      controller: "patient_sessions",
      action: access_log_entry_action
    )
  end

  def patient_id_for_logging
    params.fetch(:patient_id, params[:id])
  end
end
