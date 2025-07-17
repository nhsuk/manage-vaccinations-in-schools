# frozen_string_literal: true

class Programmes::BaseController < ApplicationController
  before_action :set_programme

  layout "full"

  private

  def set_programme
    @programme = policy_scope(Programme).find_by!(type: params[:programme_type])
  end
end
