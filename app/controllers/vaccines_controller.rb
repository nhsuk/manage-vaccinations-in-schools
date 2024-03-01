class VaccinesController < ApplicationController
  include TodaysBatchConcern

  def index
    @vaccines = policy_scope(Vaccine).order(:name)
    @todays_batch_id = todays_batch_id
  end
end
