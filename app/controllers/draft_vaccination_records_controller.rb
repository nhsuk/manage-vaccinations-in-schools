# frozen_string_literal: true

class DraftVaccinationRecordsController < ApplicationController
  include Wicked::Wizard::Translated
  include TodaysBatchConcern
  include VaccinationMailerConcern

  before_action :set_draft_vaccination_record
  before_action :set_patient_session
  before_action :set_patient
  before_action :set_session
  before_action :set_programme
  before_action :set_vaccination_record
  before_action :set_batches
  before_action :set_steps
  before_action :setup_wizard_translated
  before_action :validate_params, only: %i[update]
  before_action :set_locations

  after_action :verify_authorized

  def show
    authorize VaccinationRecord, :edit?

    render_wizard
  end

  def update
    authorize VaccinationRecord

    @draft_vaccination_record.assign_attributes(update_params)

    case current_step
    when :confirm
      handle_confirm
    when :date_and_time
      handle_date_and_time
    when :batch
      update_default_batch_for_today
    end

    if @draft_vaccination_record.editing? && current_step != :confirm
      jump_to("confirm")
    end

    render_wizard @draft_vaccination_record
  end

  private

  def validate_params
    if current_step == :date_and_time
      validator =
        DateParamsValidator.new(
          field_name: :administered_at,
          object: @draft_vaccination_record,
          params: update_params
        )

      hour = Integer(update_params["administered_at(4i)"], exception: false)
      minute = Integer(update_params["administered_at(5i)"], exception: false)
      time_valid = hour&.between?(0, 23) && minute&.between?(0, 59)

      unless validator.date_params_valid? && time_valid
        @draft_vaccination_record.errors.add(:administered_at, :invalid)
        render_wizard nil, status: :unprocessable_entity
      end
    end
  end

  def handle_date_and_time
    if @draft_vaccination_record.administered_at.nil?
      @draft_vaccination_record.errors.add(:administered_at, :blank)
    end
  end

  def handle_confirm
    return unless @draft_vaccination_record.save

    @draft_vaccination_record.write_to!(@vaccination_record)
    @vaccination_record.save!

    send_vaccination_confirmation(@vaccination_record)

    heading =
      if @vaccination_record.administered?
        t("vaccinations.flash.given")
      else
        t("vaccinations.flash.not_given")
      end

    tab = @vaccination_record.administered? ? "vaccinated" : "could-not"

    heading_link_href =
      session_patient_path(
        @session,
        id: @patient.id,
        section: "vaccinations",
        tab:
      )

    flash[:success] = {
      heading:,
      heading_link_text: @patient.full_name,
      heading_link_href:
    }
  end

  def finish_wizard_path
    if @draft_vaccination_record.editing?
      programme_vaccination_record_path(@programme, @vaccination_record)
    else
      session_vaccinations_path(@session)
    end
  end

  def update_params
    permitted_attributes = {
      batch: %i[batch_id],
      confirm: %i[notes],
      date_and_time: %i[administered_at],
      delivery: %i[delivery_site delivery_method],
      location: %i[location_name],
      reason: %i[reason],
      vaccine: %i[vaccine_id]
    }.fetch(current_step)

    params
      .fetch(:draft_vaccination_record, {})
      .permit(permitted_attributes)
      .merge(wizard_step: current_step)
  end

  def set_draft_vaccination_record
    @draft_vaccination_record =
      DraftVaccinationRecord.new(request_session: session, current_user:)
  end

  def set_patient_session
    @patient_session = @draft_vaccination_record.patient_session
  end

  def set_patient
    @patient = @patient_session.patient
  end

  def set_session
    @session = @patient_session.session
  end

  def set_programme
    @programme = @draft_vaccination_record.programme
  end

  def set_vaccination_record
    @vaccination_record =
      @draft_vaccination_record.vaccination_record || VaccinationRecord.new
  end

  def set_steps
    # Translated steps are cached after running setup_wizard_translated.
    # To allow us to run this method multiple times during a single action
    # lifecycle, we need to clear the cache.
    @wizard_translations = nil

    self.steps = @draft_vaccination_record.wizard_steps
  end

  def set_batches
    @batches =
      policy_scope(Batch)
        .where(vaccine: @draft_vaccination_record.vaccine)
        .not_expired
        .order_by_name_and_expiration
  end

  def set_locations
    @locations = policy_scope(Location).community_clinic if current_step ==
      :location
  end

  def update_default_batch_for_today
    if params.dig(:draft_vaccination_record, :todays_batch).present? &&
         update_params[:batch_id].in?(
           params[:draft_vaccination_record][:todays_batch]
         )
      self.todays_batch_id = update_params[:batch_id]
    end
  end

  def current_step
    @current_step ||= wizard_value(step)&.to_sym
  end
end
