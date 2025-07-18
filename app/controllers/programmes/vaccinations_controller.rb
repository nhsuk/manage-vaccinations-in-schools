# frozen_string_literal: true

class Programmes::VaccinationsController < Programmes::BaseController
  include Pagy::Backend

  def index
    scope =
      policy_scope(VaccinationRecord)
        .where(programme: @programme)
        .includes(:patient, :programme)
        .order(:performed_at)

    @pagy, @vaccination_records = pagy(scope)
  end
end
