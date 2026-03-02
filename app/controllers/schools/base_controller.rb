# frozen_string_literal: true

class Schools::BaseController < ApplicationController
  before_action :set_location
  before_action :set_academic_year

  layout "full"

  private

  def set_location
    urn_and_site = params[:school_urn_and_site]

    @location =
      if urn_and_site.in?([Location::URN_UNKNOWN, Location::URN_HOME_EDUCATED])
        policy_scope(Location).generic_clinic.sole
      else
        policy_scope(Location).school.find_by_urn_and_site!(
          params[:school_urn_and_site]
        )
      end

    authorize @location, policy_class: SchoolPolicy
  end

  def set_academic_year
    @academic_year = AcademicYear.current
  end
end
