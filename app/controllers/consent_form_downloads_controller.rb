# frozen_string_literal: true

class ConsentFormDownloadsController < ApplicationController
  skip_after_action :verify_policy_scoped

  CONSENT_FORM_TYPES = %w[flu hpv menacwy mmr td_ipv].freeze

  def show
    authorize ConsentForm, :download?

    type = params[:type]

    raise ActiveRecord::RecordNotFound unless CONSENT_FORM_TYPES.include?(type)

    path = "public/consent_forms/#{type}.pdf"
    name = I18n.t(type, scope: :programme_types)
    filename = "#{name} Consent Form.pdf"

    send_file(path, filename:, disposition: "attachment")
  end
end
