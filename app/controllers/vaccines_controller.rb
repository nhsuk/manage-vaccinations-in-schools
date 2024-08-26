# frozen_string_literal: true

class VaccinesController < ApplicationController
  include TodaysBatchConcern

  def index
    @vaccines = vaccines
    @todays_batch_id = todays_batch_id
  end

  def show
    @vaccine = vaccines.find(params[:id])
  end

  private

  def vaccines
    @vaccines ||= policy_scope(Vaccine).includes(:batches).order(:name)
  end
end
