# frozen_string_literal: true

class SessionDatesController < ApplicationController
  before_action :set_session
  before_action :set_draft_session_dates

  def show
    initialize_draft_from_session

    if params[:add_another] ||
         @draft_session_dates.session_dates_attributes.empty?
      add_blank_session_date
    end
  end

  def update
    @draft_session_dates.session_dates_attributes =
      fetch_draft_session_dates_from_form

    if params[:delete_date]
      delete_session_date(form_index_to_attr_index(params[:delete_date]))
      return render_with_error if @draft_session_dates.errors.any?
      render :show
    elsif params[:add_another]
      add_blank_session_date
      render :show
    else
      unless @draft_session_dates.save(context: :continue)
        return render_with_error
      end
      apply_changes_and_redirect
    end
  end

  private

  def set_session
    @session = policy_scope(Session).find_by!(slug: params[:session_slug])
  end

  def set_draft_session_dates
    @draft_session_dates =
      DraftSessionDates.new(
        request_session: session,
        current_user: current_user,
        session: @session,
        wizard_step: :dates
      )
  end

  def draft_session_dates_params
    params
      .fetch(:draft_session_dates, {})
      .permit(
        session_dates_attributes: [
          :id,
          :value,
          :_destroy,
          "value(1i)",
          "value(2i)",
          "value(3i)"
        ]
      )
      .merge(wizard_step: :dates)
  end

  def initialize_draft_from_session
    attributes = {}

    @session
      .session_dates
      .order(:value)
      .each_with_index do |session_date, index|
        attributes[index] = {
          "id" => session_date.id.to_s,
          "value" => session_date.value
        }
      end

    @draft_session_dates.session_dates_attributes = attributes
    @draft_session_dates.save!(context: :initialize)
  end

  def add_blank_session_date
    current_attrs = @draft_session_dates.session_dates_attributes
    next_index = (current_attrs.keys.map(&:to_i).max || -1) + 1
    current_attrs[next_index] = { "value" => nil }
    @draft_session_dates.session_dates_attributes = current_attrs
  end

  def render_with_error
    render :show, status: :unprocessable_content
  end

  def apply_changes_and_redirect
    @draft_session_dates.write_to!(@session)
    session.delete(@draft_session_dates.request_session_key)
    StatusUpdaterJob.perform_later(session: @session)
    redirect_to edit_session_path(@session)
  rescue ActiveRecord::RecordInvalid => e
    @draft_session_dates.errors.add(
      :base,
      "Failed to save session dates: #{e.message}"
    )
    render_with_error
  end

  def form_index_to_attr_index(form_index)
    current_attrs = @draft_session_dates.session_dates_attributes
    corresponding_form_index = -1
    current_attrs.each do |real_index, attrs|
      corresponding_form_index += 1 unless attrs["_destroy"] == "true"

      return real_index if corresponding_form_index.to_s == form_index
    end

    (
      form_index.to_i - corresponding_form_index.to_i + current_attrs.length
    ).to_s
  end

  def fetch_draft_session_dates_from_form
    current_attrs = @draft_session_dates.session_dates_attributes

    form_params = draft_session_dates_params[:session_dates_attributes] || {}

    merged_attrs = {}

    current_attrs.each do |index, attrs|
      merged_attrs[index] = attrs if attrs["_destroy"] == "true"
    end

    form_params.each do |form_index, form_attrs|
      attr_index = form_index_to_attr_index(form_index)
      merged_attrs[attr_index] = form_attrs
    end

    merged_attrs
  end

  def delete_session_date(index)
    current_attrs = @draft_session_dates.session_dates_attributes

    if current_attrs[index]
      if @draft_session_dates.non_destroyed_session_dates_count <= 1
        @draft_session_dates.errors.add(
          :base,
          "You cannot delete the last session date. A session must have at least one date."
        )
        return
      end

      current_attrs[index]["_destroy"] = "true"
      @draft_session_dates.session_dates_attributes = current_attrs
      @draft_session_dates.save!(context: :update)
    end
  end
end
