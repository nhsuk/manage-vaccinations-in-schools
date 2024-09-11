# frozen_string_literal: true

class VaccinationMailer < ApplicationMailer
  def hpv_vaccination_has_taken_place
    app_template_mail(:confirmation_the_hpv_vaccination_has_taken_place)
  end

  def hpv_vaccination_has_not_taken_place
    app_template_mail(:confirmation_the_hpv_vaccination_didnt_happen)
  end
end
