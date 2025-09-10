# frozen_string_literal: true

class Programmes::BaseController < ApplicationController
  before_action :set_programme
  before_action :set_academic_year

  layout "full"

  private

  def set_programme
    @programme = policy_scope(Programme).find_by!(type: params[:programme_type])
  end

  def set_academic_year
    @academic_year = params[:academic_year].to_i

    if @academic_year.nil? || @academic_year < 2000 || @academic_year > 2100
      raise ActiveRecord::RecordNotFound
    end
  end

  def patient_ids
    @patient_ids ||=
      PatientLocation
        .distinct
        .joins(:patient)
        .joins_sessions
        .where("sessions.id IN (?)", session_ids)
        .appear_in_programmes([@programme])
        .not_archived(team: current_team)
        .pluck(:patient_id)
  end

  def session_ids
    @session_ids ||=
      current_team
        .sessions
        .where(academic_year: @academic_year)
        .has_programmes([@programme])
        .pluck(:id)
  end
end
