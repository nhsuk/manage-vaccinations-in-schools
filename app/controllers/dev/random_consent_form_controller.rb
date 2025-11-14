# frozen_string_literal: true

class Dev::RandomConsentFormController < ApplicationController
  include DevConcern

  def call
    Faker::Config.locale = "en-GB"

    session =
      if params[:slug].present?
        Session.find_by(slug: params[:slug])
      else
        Session.find(params[:session_id])
      end

    attributes =
      if ActiveModel::Type::Boolean.new.cast(params[:parent_phone])
        {}
      else
        { parent_phone: nil }
      end

    consent_form =
      FactoryBot.create(:consent_form, :draft, session:, **attributes)

    consent_form.consent_form_programmes.find_each do |consent_form_programme|
      if consent_form_programme.flu?
        consent_form_programme.update!(vaccine_methods: %w[nasal injection])
      end
    end

    consent_form.seed_health_questions
    consent_form.each_health_answer do |health_answer|
      health_answer.response = "no"
    end
    consent_form.save!

    request.session[:consent_form_id] = consent_form.id
    redirect_to confirm_parent_interface_consent_form_path(consent_form)
  end
end
