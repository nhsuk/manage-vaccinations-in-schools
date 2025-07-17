# frozen_string_literal: true

class Programmes::OverviewController < ApplicationController
  before_action :set_programme

  layout "full"

  def show
    patients = policy_scope(Patient).in_programmes([@programme])

    @consents =
      policy_scope(Consent).where(patient: patients, programme: @programme)
  end

  private

  def set_programme
    @programme = policy_scope(Programme).find_by!(type: params[:programme_type])
  end
end
