# frozen_string_literal: true

class Programmes::VaccinationsController < ApplicationController
  include Pagy::Backend

  before_action :set_programme

  layout "full"

  def index
    scope =
      policy_scope(VaccinationRecord)
        .where(programme: @programme)
        .includes(:patient, :programme)
        .order(:performed_at)

    @pagy, @vaccination_records = pagy(scope)
  end

  private

  def set_programme
    @programme = policy_scope(Programme).find_by!(type: params[:programme_type])
  end
end
