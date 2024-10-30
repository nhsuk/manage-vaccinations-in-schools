# frozen_string_literal: true

class SessionDatesController < ApplicationController
  before_action :set_session

  def show
    @session.session_dates.build if @session.session_dates.empty?
  end

  def update
    @session.assign_attributes(remove_invalid_dates(session_params))
    @session.set_notification_dates

    render :show, status: :unprocessable_entity and return if @session.invalid?

    @session.save!

    # If deleting dates, they don't disappear from `session.dates` until
    # the model has been saved due to how `accepts_nested_attributes_for`
    # works.
    if any_destroyed?
      @session.session_dates.reload
      @session.set_notification_dates
      @session.save!
    end

    if params.include?(:add_another)
      @session.session_dates.build
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
    @session = policy_scope(Session).find_by!(slug: params[:session_slug])
  end

  def session_params
    params.require(:session).permit(
      session_dates_attributes: %i[id value _destroy]
    )
  end

  def any_destroyed?
    session_params[:session_dates_attributes].values.any? do
      _1[:_destroy].present?
    end
  end

  def remove_invalid_dates(obj, key: "session_dates_attributes")
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
