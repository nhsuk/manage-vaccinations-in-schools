# frozen_string_literal: true

class Programmes::OverviewController < Programmes::BaseController
  def show
    patients =
      policy_scope(Patient).appear_in_programmes(
        [@programme],
        academic_year: @academic_year
      )

    @consents =
      policy_scope(Consent).where(
        patient: patients,
        programme: @programme,
        submitted_at: @academic_year.to_academic_year_date_range
      )
  end
end
