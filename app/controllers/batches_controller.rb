class BatchesController < ApplicationController
  include TodaysBatchConcern

  layout "two_thirds"

  before_action :set_vaccine

  def new
    @batch = Batch.new(vaccine:)
  end

  def create
    @batch = Batch.new(batch_params.merge(vaccine:))

    if @batch.save
      flash[:success] = "Batch #{@batch.name} added"
      redirect_to vaccines_path
    else
      render :new
    end
  end

  def edit
    @batch = @vaccine.batches.find(params[:id])
  end

  def make_default
    self.todays_batch_id = params[:id]
    redirect_to vaccines_path
  end

  def remove_default
    unset_todays_batch
    redirect_to vaccines_path
  end

  def update
    @batch = @vaccine.batches.find(params[:id])

    if @batch.update(batch_params)
      flash[:success] = "Batch #{@batch.name} updated"
      redirect_to vaccines_path
    else
      render :edit
    end
  end

  private

  attr_reader :vaccine

  def set_vaccine
    @vaccine = policy_scope(Vaccine).find(params[:vaccine_id])
  end

  def batch_params
    params.require(:batch).permit(
      :name,
      :"expiry(3i)",
      :"expiry(2i)",
      :"expiry(1i)"
    )
  end
end
