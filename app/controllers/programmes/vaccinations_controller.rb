# frozen_string_literal: true

class Programmes::VaccinationsController < Programmes::BaseController
  include Pagy::Backend

  def index
    scope =
      policy_scope(VaccinationRecord)
        .where(
          programme: @programme,
          performed_at: @academic_year.to_academic_year_date_range
        )
        .includes(:patient, :programme)
        .order(:performed_at)

    @pagy, @vaccination_records = pagy(scope)
  end
end
