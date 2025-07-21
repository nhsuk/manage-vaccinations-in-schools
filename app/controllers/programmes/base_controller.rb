# frozen_string_literal: true

class Programmes::BaseController < ApplicationController
  before_action :set_programme
  before_action :set_academic_year

  layout "full"

  private

  def set_programme
    @programme = policy_scope(Programme).find_by!(type: params[:programme_type])
  end

  def set_academic_year
    @academic_year = params[:academic_year].to_i

    if @academic_year.nil? || @academic_year < 2000 || @academic_year > 2100
      raise ActiveRecord::RecordNotFound
    end
  end

  def organisation = current_user.selected_organisation
end
