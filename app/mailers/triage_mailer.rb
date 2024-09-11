# frozen_string_literal: true

class TriageMailer < ApplicationMailer
  def vaccination_will_happen
    app_template_mail(:triage_vaccination_will_happen)
  end

  def vaccination_wont_happen
    app_template_mail(:triage_vaccination_wont_happen)
  end
end
