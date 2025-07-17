# frozen_string_literal: true

class Programmes::ReportsController < ApplicationController
  before_action :set_programme

  def create
    vaccination_report =
      VaccinationReport.new(request_session: session, current_user:)

    vaccination_report.reset!
    vaccination_report.update!(programme: @programme)

    redirect_to vaccination_report_path(Wicked::FIRST_STEP)
  end

  private

  def set_programme
    @programme = policy_scope(Programme).find_by!(type: params[:programme_type])
  end
end
