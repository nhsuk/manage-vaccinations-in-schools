# frozen_string_literal: true

class ProgrammesController < ApplicationController
  before_action :set_programme, except: :index

  layout "full"

  def index
    @programmes =
      policy_scope(Programme).order(:type).includes(:active_vaccines)
  end

  def show
    patients = policy_scope(Patient).in_programmes([@programme])
    @consents =
      policy_scope(Consent).where(patient: patients, programme: @programme)
  end

  def sessions
    @sessions =
      policy_scope(Session)
        .has_programme(@programme)
        .for_current_academic_year
        .includes(:location, :session_dates)
        .order("locations.name")
  end

  def consent_form
    send_file(
      "public/consent_forms/#{@programme.type}.pdf",
      filename: "#{@programme.name} Consent Form.pdf",
      disposition: "attachment"
    )
  end

  private

  def set_programme
    @programme = authorize policy_scope(Programme).find_by!(type: params[:type])
  end
end
