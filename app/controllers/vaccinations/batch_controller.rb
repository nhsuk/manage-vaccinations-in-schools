# frozen_string_literal: true

class Vaccinations::BatchController < ApplicationController
  include TodaysBatchConcern

  before_action :set_session
  before_action :set_batches

  after_action :verify_authorized

  def edit
    @todays_batch = authorize @batches.find_by(id: todays_batch_id)
  end

  def update
    @todays_batch = authorize @batches.find_by(id: params.dig(:batch, :id))

    if @todays_batch
      self.todays_batch_id = @todays_batch.id

      flash[:success] = {
        heading: "The default batch for this session has been updated"
      }

      redirect_to session_vaccinations_path(@session)
    else
      @todays_batch = Batch.new
      @todays_batch.errors.add(:id, "Select a default batch for this session")
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_session
    @session = policy_scope(Session).find_by!(slug: params[:session_slug])
  end

  def set_batches
    @batches =
      policy_scope(Batch)
        .where(vaccine: @session.vaccines)
        .not_archived
        .not_expired
        .order_by_name_and_expiration
  end
end
