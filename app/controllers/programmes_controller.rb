# frozen_string_literal: true

class ProgrammesController < ApplicationController
  skip_after_action :verify_policy_scoped

  layout "full"

  def index
    @programmes = current_user.programmes
  end

  def consent_form
    programme =
      authorize(current_user.programmes.find { it.type == params[:type] })

    send_file(
      "public/consent_forms/#{programme.type}.pdf",
      filename: "#{programme.name} Consent Form.pdf",
      disposition: "attachment"
    )
  end
end
