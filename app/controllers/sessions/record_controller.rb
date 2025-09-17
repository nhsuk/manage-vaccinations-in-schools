# frozen_string_literal: true

require "pagy/extras/array"

class Sessions::RecordController < ApplicationController
  include PatientSearchFormConcern
  include TodaysBatchConcern

  before_action :set_session
  before_action :set_patient_search_form

  before_action :set_programme, except: :show
  before_action :set_vaccine_method, except: :show
  before_action :set_batches, except: :show

  def show
    scope =
      @session.patient_sessions.includes(
        patient: [
          :consent_statuses,
          :triage_statuses,
          :vaccination_statuses,
          { notes: :created_by }
        ]
      )

    if @session.requires_registration?
      scope = scope.has_registration_status(%w[attending completed])
    end

    patient_sessions =
      filter_on_vaccine_method_or_patient_specific_direction(
        @form.apply(scope)
      ).consent_given_and_ready_to_vaccinate(
        programmes: @form.programmes,
        vaccine_method: @form.vaccine_method.presence
      )

    @pagy, @patient_sessions = pagy_array(patient_sessions)

    render layout: "full"
  end

  def edit_batch
    id = todays_batch_id(programme: @programme, vaccine_method: @vaccine_method)
    @todays_batch = authorize @batches.find(id), :edit?

    render :batch
  end

  def update_batch
    @todays_batch =
      authorize @batches.find_by(id: params.dig(:batch, :id)), :update?

    if @todays_batch
      self.todays_batch = @todays_batch

      redirect_to session_record_path(@session),
                  flash: {
                    success:
                      "The default batch for this session has been updated"
                  }
    else
      @todays_batch = Batch.new
      @todays_batch.errors.add(:id, "Select a default batch for this session")

      render :batch, status: :unprocessable_content
    end
  end

  private

  def set_session
    @session =
      policy_scope(Session).includes(programmes: :vaccines).find_by!(
        slug: params[:session_slug]
      )
  end

  def set_programme
    @programme = policy_scope(Programme).find_by!(type: params[:programme_type])
  end

  def set_vaccine_method
    @vaccine_method = params[:vaccine_method]
  end

  def set_batches
    vaccines =
      @session.vaccines.where(programme: @programme, method: @vaccine_method)

    @batches =
      policy_scope(Batch)
        .where(vaccine: vaccines)
        .not_archived
        .not_expired
        .order_by_name_and_expiration
  end

  def filter_on_vaccine_method_or_patient_specific_direction(scope)
    return scope if current_user.is_nurse? || current_user.is_prescriber?
    return scope.none unless current_user.is_healthcare_assistant?

    original_scope = scope

    if @session.psd_enabled? && @session.national_protocol_enabled?
      original_scope.has_patient_specific_direction(
        programme: @session.programmes,
        team: current_team
      ).or(
        original_scope.has_vaccine_method(
          "injection",
          programme: @session.programmes
        )
      )
    elsif @session.pgd_supply_enabled? && @session.national_protocol_enabled?
      original_scope.has_vaccine_method(
        %w[nasal injection],
        programme: @session.programmes
      )
    elsif @session.pgd_supply_enabled?
      original_scope.has_vaccine_method("nasal", programme: @session.programmes)
    elsif @session.national_protocol_enabled?
      original_scope.has_vaccine_method(
        "injection",
        programme: @session.programmes
      )
    else
      original_scope.none
    end
  end
end
