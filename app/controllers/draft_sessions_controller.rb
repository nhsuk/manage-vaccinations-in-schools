# frozen_string_literal: true

class DraftSessionsController < ApplicationController
  before_action :set_draft_session
  before_action :set_session

  include WizardControllerConcern

  with_options only: :show, if: -> { current_step == :dates_check } do
    before_action :set_catch_up_year_groups
    before_action :set_catch_up_patients_vaccinated_percentage
    before_action :set_catch_up_patients_receiving_consent_requests_count
  end

  before_action :validate_params, only: :update
  before_action :set_back_link_path

  skip_after_action :verify_policy_scoped

  def show
    authorize @session, :edit?

    render_wizard
  end

  def update
    authorize @session, :update?

    jump_to("confirm") if @draft_session.editing? && current_step != :confirm

    if current_step == :dates
      handle_dates
    elsif current_step == :confirm
      handle_confirm
    else
      @draft_session.assign_attributes(update_params)
    end

    render_wizard @draft_session
  end

  private

  def set_draft_session
    @draft_session = DraftSession.new(request_session: session, current_user:)
  end

  def set_session
    @session = @draft_session.session
  end

  def set_steps
    self.steps = @draft_session.wizard_steps
  end

  def set_catch_up_year_groups
    @catch_up_year_groups = @draft_session.year_groups.drop(1)
  end

  def set_catch_up_patients_vaccinated_percentage
    academic_year = @draft_session.academic_year
    birth_academic_years =
      @catch_up_year_groups.map { it.to_birth_academic_year(academic_year:) }

    catch_up_patients =
      @draft_session
        .patient_locations
        .where(patient: { birth_academic_year: birth_academic_years })
        .includes(patient: :vaccination_statuses)
        .map(&:patient)

    total_count = catch_up_patients.count
    vaccinated_count =
      catch_up_patients.count do |patient|
        year_group = patient.year_group(academic_year:)
        @draft_session
          .programmes_for(patient:)
          .all? do |programme|
            if @draft_session.programme_year_groups.is_catch_up?(
                 year_group,
                 programme:
               )
              patient.vaccination_status(programme:, academic_year:).vaccinated?
            else
              true
            end
          end
      end

    @catch_up_patients_vaccinated_percentage =
      if total_count.zero? || vaccinated_count.zero?
        0
      else
        (vaccinated_count / total_count.to_f * 100).to_i
      end
  end

  def set_catch_up_patients_receiving_consent_requests_count
    patient_ids = []

    SendSchoolConsentRequestsJob
      .new
      .patients_and_programmes(@draft_session) do |patient, programmes|
        if @draft_session.patient_is_catch_up?(patient, programmes:)
          patient_ids << patient.id
        end
      end

    @catch_up_patients_receiving_consent_requests_count = patient_ids.uniq.size
  end

  def validate_params
    if current_step == :consent_requests
      unless send_consent_requests_at_validator.date_params_valid?
        @draft_session.errors.add(:send_consent_requests_at_validator, :invalid)
        render_wizard nil, status: :unprocessable_content
      end
    elsif current_step == :invitations
      unless send_invitations_at_validator.date_params_valid?
        @draft_session.errors.add(:send_consent_requests_at_validator, :invalid)
        render_wizard nil, status: :unprocessable_content
      end
    end
  end

  def set_back_link_path
    @back_link_path =
      if current_step == :confirm
        session_path(@session)
      else
        wizard_path("confirm")
      end
  end

  def handle_dates
    session_dates_attrs = update_params.except(:wizard_step)

    check_dates = true

    @draft_session
      .session_dates
      .to_enum
      .with_index
      .reverse_each do |session_date, index|
      attributes = session_dates_attrs["session_date_#{index}"]
      if attributes.present?
        if attributes["_destroy"].present?
          @draft_session.session_dates.delete_at(index)
          jump_to("dates")
          check_dates = false
        else
          # We need to do this here to get around the multi-parameter
          # assignment error being raised if we don't validate before
          # assignment.
          year = attributes["value(1i)"]
          month = attributes["value(2i)"]
          day = attributes["value(3i)"]

          next if day.blank? && month.blank? && year.blank?

          begin
            value = Date.new(year.to_i, month.to_i, day.to_i)
            session_date.assign_attributes(value:)
          rescue StandardError
            session_date.errors.add(:value, :blank)
            check_dates = false
          end
        end
      end
    end

    if session_dates_attrs["_add_another"].present?
      @draft_session.session_dates << DraftSessionDate.new
      jump_to("dates")
      check_dates = false
    end

    @draft_session.set_notification_dates

    if @draft_session.school? && check_dates
      any_programme_has_high_unvaccinated_count =
        @draft_session.programmes.any? do |programme|
          programme_has_high_unvaccinated_count?(programme)
        end

      jump_to("dates-check") if any_programme_has_high_unvaccinated_count
    end

    @draft_session.wizard_step = current_step
  end

  def handle_confirm
    return unless @draft_session.save

    @draft_session.write_to!(@session)

    ActiveRecord::Base.transaction do
      @session.save!
      @draft_session.create_location_programme_year_groups!
    end

    patient_ids = @session.patients.pluck(:id)
    StatusUpdaterJob.perform_bulk(patient_ids.zip)
  end

  def finish_wizard_path = session_path(@session)

  def update_params
    permitted_attributes = {
      consent_reminders: %i[weeks_before_consent_reminders],
      consent_requests: %i[send_consent_requests_at],
      dates: dates_params,
      dates_check: [],
      delegation: %i[psd_enabled national_protocol_enabled],
      invitations: %i[send_invitations_at],
      programmes: {
        programme_types: []
      },
      register_attendance: %i[requires_registration]
    }.fetch(current_step)

    params
      .fetch(:draft_session, {})
      .permit(permitted_attributes)
      .merge(wizard_step: current_step)
  end

  def dates_params
    n = @draft_session.session_dates&.size || 0
    [
      :_add_another,
      Array
        .new(n) { |index| ["session_date_#{index}", %i[id value _destroy]] }
        .to_h
    ]
  end

  def send_consent_requests_at_validator
    @send_consent_requests_at_validator ||=
      DateParamsValidator.new(
        field_name: :send_consent_requests_at,
        object: @draft_session,
        params: update_params
      )
  end

  def send_invitations_at_validator
    @send_invitations_at_validator ||=
      DateParamsValidator.new(
        field_name: :send_invitations_at,
        object: @draft_session,
        params: update_params
      )
  end

  def programme_has_high_unvaccinated_count?(programme)
    catch_up_year_groups =
      @draft_session.year_groups.select do |year_group|
        @draft_session.programme_year_groups.is_catch_up?(
          year_group,
          programme:
        )
      end

    return false if catch_up_year_groups.empty?

    catch_up_year_groups.any? do |year_group|
      catch_up_year_group_has_high_unvaccinated_count?(programme, year_group)
    end
  end

  def catch_up_year_group_has_high_unvaccinated_count?(programme, year_group)
    academic_year = @draft_session.academic_year
    birth_academic_year = year_group.to_birth_academic_year(academic_year:)

    # We specifically use `patient_locations` and not `patients` so we can
    # capture patients in programmes that aren't currently in the session but
    # are due to be added to the session.

    catch_up_patients =
      @draft_session
        .patient_locations
        .where(patient: { birth_academic_year: })
        .includes(patient: :vaccination_statuses)
        .map(&:patient)

    total_count = catch_up_patients.count
    vaccinated_count =
      catch_up_patients.count do |patient|
        patient.vaccination_status(programme:, academic_year:).vaccinated?
      end

    vaccinated_count < total_count / 2
  end
end
