# frozen_string_literal: true

class CohortsController < ApplicationController
  skip_after_action :verify_policy_scoped, only: :show

  def show
    @programme = Programme.find(params[:programme_id])
    @cohort = Cohort.find(params[:id])
  end
end
