# frozen_string_literal: true

class Programmes::ReportsController < Programmes::BaseController
  skip_after_action :verify_policy_scoped

  def create
    vaccination_report =
      VaccinationReport.new(request_session: session, current_user:)

    vaccination_report.clear_attributes
    vaccination_report.update!(
      programme: @programme,
      academic_year: @academic_year
    )

    redirect_to vaccination_report_path(Wicked::FIRST_STEP)
  end
end
