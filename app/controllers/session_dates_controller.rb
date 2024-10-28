# frozen_string_literal: true

class SessionDatesController < ApplicationController
  before_action :set_session

  def show
    @session.dates.build if @session.dates.empty?
  end

  def update
    @session.assign_attributes(remove_invalid_dates(session_params))

    render :show, status: :unprocessable_entity and return if @session.invalid?

    @session.set_consent_dates
    @session.save!

    if params.include?(:add_another)
      @session.dates.build
      render :show
    else
      redirect_to(
        if any_destroyed?
          session_dates_path(@session)
        else
          edit_session_path(@session)
        end
      )
    end
  end

  private

  def set_session
    @session = policy_scope(Session).find(params[:session_id])
  end

  def session_params
    params.require(:session).permit(dates_attributes: %i[id value _destroy])
  end

  def any_destroyed?
    session_params[:dates_attributes].values.any? { _1[:_destroy].present? }
  end

  def remove_invalid_dates(obj, key: "dates_attributes")
    return obj if obj[key].blank?

    obj[key] = obj[key].transform_values do |value|
      if value.key?("value(1i)") && value.key?("value(2i)") &&
           value.key?("value(3i)")
        begin
          Date.new(
            value["value(1i)"].to_i,
            value["value(2i)"].to_i,
            value["value(3i)"].to_i
          )
          value
        rescue StandardError
          {}
        end
      else
        value
      end
    end

    obj
  end
end
