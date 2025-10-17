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
  before_action :set_supplied_by_users, if: -> { current_step == :supplier }
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

    reload_steps

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
        render_wizard nil, status: :unprocessable_content
      end
    end
  end

  def handle_date_and_time
    if @draft_vaccination_record.performed_at.nil?
      @draft_vaccination_record.errors.add(:performed_at, :blank)
    end
  end

  def handle_outcome
    if !@draft_vaccination_record.administered? &&
         @draft_vaccination_record.location_id.present?
      # If not administered and location is set, we can skip to confirm.
      # Otherwise, we need to get the location information from the user.
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

    is_new_record = @vaccination_record.new_record?

    performed_at_date_changed =
      @vaccination_record.performed_at&.to_date !=
        @draft_vaccination_record.performed_at.to_date

    @draft_vaccination_record.write_to!(@vaccination_record)

    @vaccination_record.source = "service"

    should_notify_parents =
      @vaccination_record.confirmation_sent? &&
        (
          @vaccination_record.outcome_changed? ||
            @vaccination_record.batch_id_changed? || performed_at_date_changed
        )
    if is_new_record
      @vaccination_record.notify_parents =
        VaccinationNotificationCriteria.call(
          vaccination_record: @vaccination_record
        )
    end
    @vaccination_record.save!

    StatusUpdater.call(patient: @patient)

    send_vaccination_confirmation(@vaccination_record) if should_notify_parents

    # In case the user navigates back to try and edit the newly created
    # vaccination record.
    @draft_vaccination_record.update!(editing_id: @vaccination_record.id)

    flash[
      :success
    ] = "Vaccination outcome recorded for #{@programme.name_in_sentence}"
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
      vaccination_record_path(@vaccination_record)
    end
  end

  def update_params
    permitted_attributes = {
      batch: %i[batch_id],
      confirm: @draft_vaccination_record.editing? ? [] : %i[notes],
      date_and_time: %i[performed_at],
      delivery: %i[delivery_site delivery_method],
      dose: %i[full_dose],
      identity: %i[
        identity_check_confirmed_by_patient
        identity_check_confirmed_by_other_name
        identity_check_confirmed_by_other_relationship
      ],
      location: %i[location_id],
      notes: %i[notes],
      outcome: %i[outcome],
      supplier: %i[supplied_by_user_id]
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
      @draft_vaccination_record.vaccination_record ||
        VaccinationRecord.new(
          patient: @patient,
          session: @session,
          programme: @programme
        )
  end

  def set_steps
    self.steps = @draft_vaccination_record.wizard_steps
  end

  def set_batches
    vaccines = vaccine_criteria.apply(@programme.vaccines)

    scope = policy_scope(Batch).includes(:vaccine)

    @batches =
      scope
        .where(id: @draft_vaccination_record.batch_id)
        .or(scope.not_archived.not_expired.where(vaccine: vaccines))
        .order_by_name_and_expiration
  end

  def set_locations
    @locations = policy_scope(Location).community_clinic
  end

  def set_supplied_by_users
    @supplied_by_users = current_team.users.show_in_suppliers
  end

  def set_back_link_path
    @back_link_path =
      if @draft_vaccination_record.editing?
        if current_step == :confirm
          vaccination_record_path(@vaccination_record)
        else
          wizard_path("confirm")
        end
      elsif first_step_of_flow?
        session_patient_programme_path(@session, @patient, @programme)
      else
        previous_wizard_path
      end
  end

  def first_step_of_flow?
    current_step.to_s == @draft_vaccination_record.first_active_wizard_step ||
      current_step == @draft_vaccination_record.wizard_steps.first
  end

  def vaccine_criteria
    vaccine_method =
      Vaccine.delivery_method_to_vaccine_method(
        @draft_vaccination_record.delivery_method
      )

    without_gelatine =
      @patient.vaccine_criteria(
        programme: @programme,
        academic_year: @session.academic_year
      ).without_gelatine

    VaccineCriteria.new(
      vaccine_methods: [vaccine_method].compact,
      without_gelatine:
    )
  end
end
