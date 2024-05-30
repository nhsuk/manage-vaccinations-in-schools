class VaccinesController < ApplicationController
  include TodaysBatchConcern

  layout "two_thirds"

  def index
    @vaccines = policy_scope(Vaccine).order(:name)
    @todays_batch_id = todays_batch_id
  end

  def show
    @vaccine = policy_scope(Vaccine).find(params[:id])
  end
end
