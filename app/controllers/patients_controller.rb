# frozen_string_literal: true

class PatientsController < ApplicationController
  include Pagy::Backend

  before_action :set_patient, except: :index
  before_action :record_access_log_entry, only: %i[show log]

  def index
    scope = policy_scope(Patient).not_deceased

    if (@filter_name = params[:name]).present?
      @filter_name.strip!
      scope = scope.search_by_name(@filter_name)
    end

    if (
         @filter_missing_nhs_number =
           ActiveModel::Type::Boolean.new.cast(params[:missing_nhs_number])
       )
      scope = scope.without_nhs_number
    end

    @filtered = @filter_name.present? || @filter_missing_nhs_number

    @pagy, @patients = pagy(scope.order_by_name)

    @heading = [
      I18n.t("children", count: @pagy.count),
      @filter_name.present? ? "matching “#{@filter_name}”" : nil,
      @filter_missing_nhs_number ? "without an NHS number" : nil
    ].compact.join(" ")

    render layout: "full", status: request.post? ? :created : :ok
  end

  def show
    @sessions =
      policy_scope(Session)
        .joins(:patients)
        .where(patients: @patient)
        .includes(:location)
  end

  def log
  end

  def edit
  end

  def update
    old_cohort = @patient.cohort

    cohort_id = params.dig(:patient, :cohort_id).presence

    ActiveRecord::Base.transaction do
      @patient.update!(cohort_id:)

      if cohort_id.nil?
        @patient
          .patient_sessions
          .includes(:session_attendances)
          .where(session: old_cohort.organisation.sessions)
          .find_each(&:destroy_if_safe!)
      end
    end

    path =
      (
        if policy_scope(Patient).include?(@patient)
          patient_path(@patient)
        else
          patients_path
        end
      )

    redirect_to path,
                flash: {
                  success:
                    "#{@patient.full_name} removed from #{helpers.format_year_group(old_cohort.year_group)} cohort"
                }
  end

  private

  def set_patient
    @patient =
      policy_scope(Patient).includes(
        :gillick_assessments,
        :gp_practice,
        :school,
        :triages,
        cohort: :organisation,
        consents: %i[parent patient],
        parent_relationships: :parent,
        patient_sessions: %i[location session_attendances],
        vaccination_records: [{ vaccine: :programme }]
      ).find(params[:id])
  end

  def record_access_log_entry
    @patient.access_log_entries.create!(
      user: current_user,
      controller: "patients",
      action: action_name
    )
  end
end
