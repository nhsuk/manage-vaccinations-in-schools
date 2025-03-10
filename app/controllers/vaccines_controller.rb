# frozen_string_literal: true

class VaccinesController < ApplicationController
  include TodaysBatchConcern

  layout "full"

  def index
    @vaccines = policy_scope(Vaccine).includes(:programme).active.order(:brand)

    @batches_by_vaccine_id =
      policy_scope(Batch)
        .where(vaccine: @vaccines)
        .not_archived
        .order_by_name_and_expiration
        .group_by(&:vaccine_id)

    @todays_batch_id_by_programme =
      policy_scope(Programme).index_with do |programme|
        todays_batch_id(programme:)
      end
  end

  def show
    @vaccine = policy_scope(Vaccine).active.find(params[:id])
    @batches = policy_scope(Batch).not_archived.where(vaccine: @vaccine)
  end
end
