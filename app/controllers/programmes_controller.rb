# frozen_string_literal: true

class ProgrammesController < ApplicationController
  before_action :set_programme, except: :index

  layout "full"

  def index
    @programmes = authorize policy_scope(Programme)
  end

  def show
    authorize @programme
  end

  def sessions
    sessions_for_programme =
      policy_scope(Session).has_programme(@programme).includes(
        :dates,
        :location
      )
    authorize sessions_for_programme, :index?

    @scheduled_sessions =
      sessions_for_programme.scheduled.sort_by do |session|
        [session.dates.first.value, session.location&.name]
      end

    @unscheduled_sessions =
      sessions_for_programme.unscheduled.order_by_location_name
    @completed_sessions =
      sessions_for_programme.completed.sort_by do |session|
        [session.dates.first.value, session.location&.name]
      end
  end

  private

  def set_programme
    @programme = policy_scope(Programme).find(params[:id])
  end
end
