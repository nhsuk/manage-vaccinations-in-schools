# frozen_string_literal: true

class Dev::RandomConsentFormController < ApplicationController
  include DevConcern

  def call
    Faker::Config.locale = "en-GB"

    session = Session.includes(programmes: :vaccines).find(params[:session_id])

    attributes =
      if ActiveModel::Type::Boolean.new.cast(params[:parent_phone])
        {}
      else
        { parent_phone: nil }
      end

    consent_form =
      FactoryBot.create(:consent_form, :draft, session:, **attributes)

    consent_form.seed_health_questions
    consent_form.each_health_answer do |health_answer|
      health_answer.response = "no"
    end
    consent_form.save!

    request.session[:consent_form_id] = consent_form.id
    redirect_to confirm_parent_interface_consent_form_path(consent_form)
  end
end
