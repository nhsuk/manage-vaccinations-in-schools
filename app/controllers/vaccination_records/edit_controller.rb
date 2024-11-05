# frozen_string_literal: true

class VaccinationRecords::EditController < ApplicationController
  include Wicked::Wizard::Translated
  include TodaysBatchConcern
  include VaccinationMailerConcern

  before_action :set_vaccination_record
  before_action :set_patient
  before_action :set_session
  before_action :set_programme
  before_action :set_batches
  before_action :set_steps
  before_action :setup_wizard_translated
  before_action :set_locations

  after_action :verify_authorized

  def show
    authorize @vaccination_record, :edit?

    render_wizard
  end

  def update
    authorize @vaccination_record

    @vaccination_record.assign_attributes(update_params)

    case current_step
    when :confirm
      handle_confirm
    when :date_and_time
      handle_date_and_time
    when :batch
      update_default_batch_for_today
    end

    if @vaccination_record.recorded? && current_step != :confirm
      jump_to("confirm")
    end

    render_wizard @vaccination_record
  end

  private

  def handle_date_and_time
    if @vaccination_record.administered_at.nil?
      @vaccination_record.errors.add(:administered_at, :blank)
    end
  end

  def handle_confirm
    return if @vaccination_record.recorded?

    @vaccination_record.recorded_at = Time.current

    if @vaccination_record.save
      send_vaccination_confirmation(@vaccination_record)

      session.delete(:delivery_site_other)

      heading =
        if @vaccination_record.administered?
          t("vaccinations.flash.given")
        else
          t("vaccinations.flash.not_given")
        end

      tab =
        if @vaccination_record.recorded?
          @vaccination_record.administered? ? "vaccinated" : "could-not"
        else
          "vaccinate"
        end

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
  end

  def finish_wizard_path
    if session[:return_to] == "session"
      session.delete(:return_to)
      session_vaccinations_path(@session)
    else
      programme_vaccination_record_path(@programme, @vaccination_record)
    end
  end

  def update_params
    permitted_attributes = {
      batch: %i[batch_id],
      confirm: %i[notes],
      date_and_time: %i[administered_at],
      delivery_site: %i[delivery_site delivery_method],
      location: %i[location_name],
      reason: %i[reason]
    }.fetch(current_step)

    params
      .fetch(:vaccination_record, {})
      .permit(permitted_attributes)
      .merge(wizard_step: current_step)
  end

  def set_vaccination_record
    @vaccination_record =
      policy_scope(VaccinationRecord)
        .eager_load(:patient, :programme)
        .where(programme: { type: params[:programme_type] })
        .find(params[:vaccination_record_id])

    if session[:delivery_site_other] == "true"
      @vaccination_record.delivery_site_other = true
    end

    if (id = todays_batch_id).present?
      @vaccination_record.todays_batch = policy_scope(Batch).find_by(id:)
    end
  end

  def set_patient
    @patient = @vaccination_record.patient
  end

  def set_session
    @session = @vaccination_record.session
  end

  def set_programme
    @programme = @vaccination_record.programme
  end

  def vaccination_record_params
    params.require(:vaccination_record).permit(:administered_at)
  end

  def set_steps
    # Translated steps are cached after running setup_wizard_translated.
    # To allow us to run this method multiple times during a single action
    # lifecycle, we need to clear the cache.
    @wizard_translations = nil

    self.steps = @vaccination_record.wizard_steps
  end

  def set_batches
    @batches =
      policy_scope(Batch).where(
        vaccine: @vaccination_record.vaccine
      ).order_by_name_and_expiration
  end

  def set_locations
    @locations = policy_scope(Location).community_clinic if step == "location"
  end

  def update_default_batch_for_today
    if params.dig(:vaccination_record, :todays_batch).present? &&
         update_params[:batch_id].in?(
           params[:vaccination_record][:todays_batch]
         )
      self.todays_batch_id = update_params[:batch_id]
    end
  end

  def current_step
    @current_step ||= wizard_value(step).to_sym
  end
end
