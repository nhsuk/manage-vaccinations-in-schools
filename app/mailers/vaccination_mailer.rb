# frozen_string_literal: true

class VaccinationMailer < ApplicationMailer
  def confirmation_administered
    app_template_mail(:vaccination_confirmation_administered)
  end

  def confirmation_not_administered
    app_template_mail(:vaccination_confirmation_not_administered)
  end
end
