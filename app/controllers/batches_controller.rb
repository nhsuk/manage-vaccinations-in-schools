# frozen_string_literal: true

class BatchesController < ApplicationController
  include TodaysBatchConcern

  before_action :set_vaccine
  before_action :set_batch, except: %i[new create make_default]

  def new
    @batch = Batch.new(team: current_user.team, vaccine:)
  end

  def create
    expiry =
      begin
        Date.new(
          batch_params["expiry(1i)"].to_i,
          batch_params["expiry(2i)"].to_i,
          batch_params["expiry(3i)"].to_i
        )
      rescue StandardError
        nil
      end

    @batch =
      Batch.archived.find_or_initialize_by(
        name: batch_params[:name],
        team: current_user.team,
        expiry:,
        vaccine:
      )

    if @batch.persisted?
      @batch.unarchive!
    elsif !expiry_validator.date_params_valid? || !@batch.valid?
      @batch.expiry = expiry_validator.date_params_as_struct
      render :new, status: :unprocessable_entity
      return
    else
      @batch.save!
    end

    flash[:success] = "Batch #{@batch.name} added"
    redirect_to vaccines_path
  end

  def edit
  end

  def make_default
    self.todays_batch_id = params[:id]
    redirect_to vaccines_path
  end

  def update
    if !expiry_validator.date_params_valid?
      @batch.expiry = expiry_validator.date_params_as_struct
      render :edit, status: :unprocessable_entity
    elsif !@batch.update(batch_params)
      render :edit, status: :unprocessable_entity
    else
      flash[:success] = "Batch #{@batch.name} updated"
      redirect_to vaccines_path
    end
  end

  def edit_archive
    render :archive
  end

  def update_archive
    @batch.archive!

    redirect_to vaccines_path, flash: { success: "Batch archived." }
  end

  private

  attr_reader :vaccine

  def set_vaccine
    @vaccine = policy_scope(Vaccine).find(params[:vaccine_id])
  end

  def set_batch
    @batch = @vaccine.batches.find(params[:id])
  end

  def batch_params
    params.require(:batch).permit(
      :name,
      :"expiry(3i)",
      :"expiry(2i)",
      :"expiry(1i)"
    )
  end

  def expiry_validator
    @expiry_validator ||=
      DateParamsValidator.new(
        field_name: :expiry,
        object: @batch,
        params: batch_params
      )
  end
end
