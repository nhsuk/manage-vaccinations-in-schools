# frozen_string_literal: true

class VaccinesController < ApplicationController
  include TodaysBatchConcern

  layout "full"

  def index
    @vaccines = policy_scope(Vaccine).active.order(:brand)

    @batches_by_vaccine_id =
      policy_scope(Batch)
        .where(vaccine: @vaccines)
        .not_archived
        .order_by_name_and_expiration
        .group_by(&:vaccine_id)

    @todays_batch_id_by_programme_and_vaccine_methods =
      policy_scope(Programme).index_with do |programme|
        programme.vaccine_methods.index_with do |vaccine_method|
          todays_batch_id(programme:, vaccine_method:)
        end
      end
  end

  def show
    @vaccine = policy_scope(Vaccine).active.find(params[:id])
    @batches = policy_scope(Batch).not_archived.where(vaccine: @vaccine)
  end
end
