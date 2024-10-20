# frozen_string_literal: true

class VaccinationRecords::EditController < ApplicationController
  before_action :set_vaccination_record
  before_action :set_programme

  def edit_date_and_time
    render :date_and_time
  end

  def update_date_and_time
    @vaccination_record.assign_attributes(vaccination_record_params)

    if @vaccination_record.administered_at.nil?
      @vaccination_record.errors.add(:administered_at, :blank)
      render :date_and_time, status: :unprocessable_entity
    elsif @vaccination_record.save
      redirect_to programme_vaccination_record_path(
                    @programme,
                    @vaccination_record
                  )
    else
      render :date_and_time, status: :unprocessable_entity
    end
  end

  private

  def set_vaccination_record
    @vaccination_record =
      policy_scope(VaccinationRecord)
        .where(programme: params[:programme_id])
        .includes(:programme)
        .find(params[:vaccination_record_id])
  end

  def set_programme
    @programme = @vaccination_record.programme
  end

  def vaccination_record_params
    params.require(:vaccination_record).permit(:administered_at)
  end
end
