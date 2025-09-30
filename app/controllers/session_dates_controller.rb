# frozen_string_literal: true

class SessionDatesController < ApplicationController
  before_action :set_session
  before_action :set_back_link_path

  def show
    @session.session_dates.build if @session.session_dates.empty?
  end

  def update
    @session.assign_attributes(remove_invalid_dates(session_params))

    render :show, status: :unprocessable_content and return if @session.invalid?

    @session.save!
    update_notification_dates!

    # If deleting dates, they don't disappear from `session.dates` until
    # the model has been saved due to how `accepts_nested_attributes_for`
    # works.
    if any_destroyed?
      @session.save!

      update_notification_dates!
    end

    StatusUpdaterJob.perform_later(session: @session)

    if params.include?(:add_another)
      @session.session_dates.build
      render :show
    else
      redirect_to(
        (any_destroyed? ? session_dates_path(@session) : @back_link_path)
      )
    end
  end

  private

  def set_session
    @session = policy_scope(Session).find_by!(slug: params[:session_slug])
  end

  def set_back_link_path
    @back_link_path = draft_session_path("confirm")
  end

  def update_notification_dates!
    draft_session = DraftSession.new(request_session: session, current_user:)
    draft_session.set_notification_dates
    draft_session.save!
  end

  def session_params
    params.expect(
      session: {
        session_dates_attributes: [%i[id value _destroy]]
      }
    )
  end

  def any_destroyed?
    session_params[:session_dates_attributes].values.any? do
      it[:_destroy].present?
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
