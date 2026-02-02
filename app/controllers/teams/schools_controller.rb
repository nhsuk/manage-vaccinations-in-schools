# frozen_string_literal: true

class Teams::SchoolsController < ApplicationController
  before_action :set_school
  before_action :authorize_school
  skip_after_action :verify_policy_scoped

  def edit_name
  end

  def update_name
    @school.assign_attributes(school_params)

    NameValidator.new(attributes: [:name], school_name: true).validate_each(
      @school,
      :name,
      @school.name
    )

    if @school.errors.empty? && @school.save
      redirect_to edit_team_school_path(@school)
    else
      render :edit_name, status: :unprocessable_entity
    end
  end

  def edit_address
  end

  def update_address
    @school.assign_attributes(school_params)

    %i[address_line_1 address_town address_postcode].each do |field|
      @school.errors.add(field, :blank) if @school.send(field).blank?
    end

    PostcodeValidator.new(
      attributes: [:address_postcode],
      postcode: true
    ).validate_each(@school, :address_postcode, @school.address_postcode)

    if @school.errors.empty? && @school.save
      redirect_to edit_team_school_path(@school)
    else
      render :edit_address, status: :unprocessable_entity
    end
  end

  private

  def authorize_school
    authorize @school, :edit?, policy_class: SchoolPolicy
  end

  def set_school
    @school =
      current_team
        .schools
        .includes(:location_programme_year_groups)
        .find_by_urn_and_site!(params[:id])
  end

  def school_params
    params.require(:location).permit(
      :name,
      :address_line_1,
      :address_line_2,
      :address_town,
      :address_postcode
    )
  end
end
