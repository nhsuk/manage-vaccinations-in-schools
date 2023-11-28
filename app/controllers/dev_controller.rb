require "rake"

class DevController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :ensure_dev_env

  def reset
    ActiveRecord::Base.connection.transaction do
      data_tables =
        ActiveRecord::Base.connection.tables -
          %w[users schema_migrations ar_internal_metadata]
      data_tables.each do |table|
        ActiveRecord::Base.connection.execute(
          "TRUNCATE #{table} RESTART IDENTITY CASCADE"
        )
      end

      LoadExampleCampaign.load(
        example_file: "db/sample_data/example-hpv-campaign.json"
      )
      LoadExampleCampaign.load(
        example_file: "db/sample_data/example-flu-campaign.json",
        new_campaign: true
      )
    end

    redirect_to root_path
  end

  def random_consent_form
    Faker::Config.locale = "en-GB"
    @session = Session.find(params.fetch(:session_id))
    @vaccine = @session.campaign.vaccines.first
    @consent_form =
      FactoryBot.build :consent_form, session_id: @session.id, recorded_at: nil
    @consent_form.health_questions = @vaccine.health_questions.in_order
    @consent_form.save!
    @consent_form.each_health_answer do |health_answer|
      health_answer.response = "no"
    end
    @consent_form.save!
    session[:consent_form_id] = @consent_form.id
    redirect_to session_consent_form_confirm_path(@session, @consent_form)
  end

  private

  def ensure_dev_env
    unless Rails.env.development? || Rails.env.test?
      raise "Not in development environment"
    end
  end
end
