# frozen_string_literal: true

class DraftVaccinationRecordsController < ApplicationController
  include TodaysBatchConcern
  include VaccinationMailerConcern

  skip_after_action :verify_policy_scoped

  before_action :set_draft_vaccination_record
  before_action :set_patient
  before_action :set_session
  before_action :set_programme
  before_action :set_vaccination_record

  include WizardControllerConcern

  before_action :validate_params, only: :update
  before_action :set_batches, if: -> { current_step == :batch }
  before_action :set_locations, if: -> { current_step == :location }
  before_action :set_back_link_path

  after_action :verify_authorized

  def show
    authorize @vaccination_record,
              @vaccination_record.new_record? ? :new? : :edit?

    render_wizard
  end

  def update
    authorize @vaccination_record,
              @vaccination_record.new_record? ? :create? : :update?

    @draft_vaccination_record.assign_attributes(update_params)

    case current_step
    when :date_and_time
      handle_date_and_time
    when :outcome
      handle_outcome
    when :batch
      handle_batch
    when :confirm
      handle_confirm
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
          field_name: :performed_at,
          object: @draft_vaccination_record,
          params: update_params
        )

      hour = Integer(update_params["performed_at(4i)"], exception: false)
      minute = Integer(update_params["performed_at(5i)"], exception: false)
      time_valid = hour&.between?(0, 23) && minute&.between?(0, 59)

      unless validator.date_params_valid? && time_valid
        @draft_vaccination_record.errors.add(:performed_at, :invalid)
        render_wizard nil, status: :unprocessable_entity
      end
    end
  end

  def handle_date_and_time
    if @draft_vaccination_record.performed_at.nil?
      @draft_vaccination_record.errors.add(:performed_at, :blank)
    end
  end

  def handle_outcome
    if @draft_vaccination_record.administered?
      @draft_vaccination_record.full_dose = true
    else
      # If not administered we can skip the remaining steps as they're not relevant.
      jump_to("confirm")
    end
  end

  def handle_batch
    if params.dig(:draft_vaccination_record, :todays_batch).present? &&
         update_params[:batch_id].in?(
           params[:draft_vaccination_record][:todays_batch]
         )
      self.todays_batch = policy_scope(Batch).find(update_params[:batch_id])
    end
  end

  def handle_confirm
    return unless @draft_vaccination_record.save

    performed_at_date_changed =
      @vaccination_record.performed_at&.to_date !=
        @draft_vaccination_record.performed_at.to_date

    @draft_vaccination_record.write_to!(@vaccination_record)

    should_notify_parents =
      @vaccination_record.confirmation_sent? &&
        (
          @vaccination_record.outcome_changed? ||
            @vaccination_record.batch_id_changed? || performed_at_date_changed
        )

    @vaccination_record.save!

    StatusUpdater.call(patient: @patient)

    send_vaccination_confirmation(@vaccination_record) if should_notify_parents

    @vaccination_record.triage_patient_as_do_not_vaccinate!

    # In case the user navigates back to try and edit the newly created
    # vaccination record.
    @draft_vaccination_record.update!(editing_id: @vaccination_record.id)

    flash[:success] = "Vaccination outcome recorded for #{@programme.name}"
  end

  def finish_wizard_path
    if @session.today?
      session_patient_programme_path(
        @session,
        @patient,
        @programme,
        return_to: "record"
      )
    else
      programme_vaccination_record_path(@programme, @vaccination_record)
    end
  end

  def update_params
    permitted_attributes = {
      batch: %i[batch_id],
      confirm: @draft_vaccination_record.editing? ? [] : %i[notes],
      date_and_time: %i[performed_at],
      delivery: %i[delivery_site delivery_method],
      location: %i[location_name],
      notes: %i[notes],
      outcome: %i[outcome]
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

  def set_patient
    @patient = @draft_vaccination_record.patient
  end

  def set_session
    @session = @draft_vaccination_record.session
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
    scope =
      policy_scope(Batch).includes(:vaccine).where(
        vaccine: {
          programme: @programme
        }
      )

    method =
      if @draft_vaccination_record.delivery_method == "nasal_spray"
        "nasal_spray"
      else
        "injection"
      end

    @batches =
      scope
        .where(id: @draft_vaccination_record.batch_id)
        .or(scope.not_archived.not_expired.where(vaccine: { method: }))
        .order_by_name_and_expiration
  end

  def set_locations
    @locations = policy_scope(Location).community_clinic
  end

  def set_back_link_path
    @back_link_path =
      if @draft_vaccination_record.editing?
        if current_step == :confirm
          programme_vaccination_record_path(@programme, @vaccination_record)
        else
          wizard_path("confirm")
        end
      elsif current_step == @draft_vaccination_record.wizard_steps.first
        session_patient_programme_path(@session, @patient, @programme)
      else
        previous_wizard_path
      end
  end
end
