class BatchesController < ApplicationController
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
