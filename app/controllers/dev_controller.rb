# frozen_string_literal: true

class DevController < ApplicationController
  skip_before_action :authenticate_user!
  skip_after_action :verify_policy_scoped

  before_action :ensure_dev_env

  def reset
    Faker::Config.locale = "en-GB"

    ActiveRecord::Base.connection.transaction do
      data_tables =
        ActiveRecord::Base.connection.tables -
          %w[
            users
            schema_migrations
            ar_internal_metadata
            flipper_features
            flipper_gates
          ]
      data_tables.each do |table|
        safe_table_name = ActiveRecord::Base.connection.quote_table_name(table)
        ActiveRecord::Base.connection.execute(
          "TRUNCATE #{safe_table_name} RESTART IDENTITY CASCADE"
        )
      end

      user =
        User.find_by(email: "nurse.joy@example.com") ||
          FactoryBot.create(
            :user,
            full_name: "Nurse Joy",
            email: "nurse.joy@example.com",
            password: "nurse.joy@example.com"
          )
      Audited
        .audit_class
        .as_user(user) do
          FactoryBot.create(
            :example_campaign,
            :in_progress,
            :in_past,
            :in_future,
            :hpv,
            user:
          )
        end
    end

    redirect_to root_path
  end

  def random_consent_form
    Faker::Config.locale = "en-GB"
    @session = Session.find(params.fetch(:session_id))
    @vaccine = @session.campaign.vaccines.first
    @consent_form =
      FactoryBot.build :consent_form, :draft, session_id: @session.id
    @consent_form.health_answers = @vaccine.health_questions.to_health_answers
    @consent_form.save!
    @consent_form.each_health_answer do |health_answer|
      health_answer.response = "no"
    end
    @consent_form.save!
    session[:consent_form_id] = @consent_form.id
    redirect_to session_parent_interface_consent_form_confirm_path(
                  @session,
                  @consent_form
                )
  end

  private

  def ensure_dev_env
    unless Rails.env.development? || Rails.env.test?
      raise "Not in development environment"
    end
  end
end
