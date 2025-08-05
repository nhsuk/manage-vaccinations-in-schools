# frozen_string_literal: true

class ProgrammesController < ApplicationController
  layout "full"

  def index
    @programmes = policy_scope(Programme).order(:type)
  end

  def consent_form
    programme = authorize policy_scope(Programme).find_by!(type: params[:type])

    send_file(
      "public/consent_forms/#{programme.type}.pdf",
      filename: "#{programme.name} Consent Form.pdf",
      disposition: "attachment"
    )
  end
end
