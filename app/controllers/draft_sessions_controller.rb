# frozen_string_literal: true

class DraftSessionsController < ApplicationController
  before_action :set_draft_session
  before_action :set_session

  include WizardControllerConcern

  before_action :set_schools, if: -> { current_step == :school }
  before_action :set_programmes, if: -> { current_step == :programmes }
  before_action :set_year_group_options, if: -> { current_step == :year_groups }

  with_options only: :show, if: -> { current_step == :dates_check } do
    before_action :set_catch_up_year_groups
    before_action :set_catch_up_patients_vaccinated_percentage
    before_action :set_catch_up_patients_receiving_consent_requests_count
  end

  before_action :validate_params, only: :update
  before_action :set_back_link_path

  skip_after_action :verify_policy_scoped

  def show
    authorize @session, @session.new_record? ? :new? : :edit?

    skip_step if current_step == :dates_check && should_skip_dates_check?

    render_wizard
  end

  def update
    authorize @session, @session.new_record? ? :create? : :update?

    case current_step
    when :dates
      handle_dates
    when :confirm
      handle_confirm
    else
      @draft_session.assign_attributes(update_params)
    end

    jump_to("confirm") if go_to_confirm_after_submission?

    reload_steps

    render_wizard @draft_session
  end

  private

  def set_draft_session
    @draft_session = DraftSession.new(request_session: session, current_user:)
  end

  def set_session
    @session = @draft_session.session || Session.new
  end

  def set_steps
    self.steps = @draft_session.wizard_steps
  end

  def set_schools
    @schools =
      policy_scope(Location)
        .school
        .joins(:team_locations)
        .where(
          team_locations: {
            team: @draft_session.team,
            academic_year: @draft_session.academic_year
          }
        )
  end

  def set_programmes
    @programmes = @draft_session.location.programmes & current_team.programmes
  end

  def set_year_group_options
    programmes_in_session = @draft_session.programmes

    @year_group_options =
      @draft_session
        .location
        .location_year_groups
        .includes(:location_programme_year_groups)
        .where(academic_year: @draft_session.academic_year)
        .order(:value)
        .map do |location_year_group|
          value = location_year_group.value
          text = helpers.format_year_group(value)

          missing_programmes =
            programmes_in_session - location_year_group.programmes
          only_programmes = programmes_in_session - missing_programmes

          hint =
            if only_programmes == programmes_in_session
              nil
            else
              "#{only_programmes.map(&:name).to_sentence} only"
            end

          OpenStruct.new(value:, text:, hint:)
        end
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
            if programme.is_catch_up?(year_group:)
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
      if @draft_session.editing? && current_step == :confirm
        finish_wizard_path
      elsif @draft_session.editing?
        wizard_path("confirm")
      elsif current_step == @draft_session.wizard_steps.first
        @draft_session.return_to == "school" ? schools_path : sessions_path
      else
        previous_wizard_path
      end
  end

  def handle_dates
    session_dates_attrs = update_params.except(:wizard_step)

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
          end
        end
      end
    end

    if session_dates_attrs["_add_another"].present?
      @draft_session.session_dates << DraftSessionDate.new
      jump_to("dates")
    end

    @draft_session.set_notification_dates

    @draft_session.wizard_step = current_step
  end

  def handle_confirm
    return unless @draft_session.save

    @draft_session.write_to!(@session)

    ActiveRecord::Base.transaction do
      @session.save!
      @draft_session.create_session_programme_year_groups!(@session)
    end

    @draft_session.session = @session
    @draft_session.save!

    patient_ids = @session.patients.pluck(:id)
    StatusUpdaterJob.perform_bulk(patient_ids.zip)
  end

  def finish_wizard_path
    if Flipper.enabled?(:schools_and_sessions) &&
         @draft_session.return_to == "school"
      location = @draft_session.location
      school_sessions_path(
        location.generic_clinic? ? Location::URN_UNKNOWN : location
      )
    else
      session_path(@session)
    end
  end

  def update_params
    permitted_attributes = {
      consent_reminders: %i[weeks_before_consent_reminders],
      consent_requests: %i[send_consent_requests_at],
      dates: dates_params,
      dates_check: [],
      delegation: %i[psd_enabled national_protocol_enabled],
      invitations: %i[send_invitations_at],
      location_type: %i[location_type],
      programmes: {
        programme_types: []
      },
      register_attendance: %i[requires_registration],
      school: %i[location_id],
      year_groups: {
        year_groups: []
      }
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

  def go_to_confirm_after_submission?
    # Something earlier has jumped to a specific step.
    return false if @skip_to.present?

    # After the `dates` and `programmes` steps, we have a check page which
    # means we can't always skip straight to the confirmation page.

    if current_step == :dates && steps.include?("dates-check") &&
         !should_skip_dates_check?
      return false
    end

    # If we're creating a new session, then we skip a few of the later steps
    # in the journey, but users can go to them via the check and confirm page.

    has_finished_initial_steps =
      @draft_session.dates.present? && @draft_session.programmes.present? &&
        @draft_session.year_groups.present?

    if @draft_session.editing? || has_finished_initial_steps
      return current_step != :confirm
    end

    current_step == :dates_check ||
      (
        current_step == :dates && steps.include?("dates-check") &&
          should_skip_dates_check?
      ) || (current_step == :dates && !steps.include?("dates-check"))
  end

  def should_skip_dates_check?
    if @draft_session.editing? &&
         @draft_session.session.dates == @draft_session.dates
      return true
    end

    any_programme_has_high_unvaccinated_count =
      @draft_session.programmes.any? do |programme|
        programme_has_high_unvaccinated_count?(programme)
      end

    !any_programme_has_high_unvaccinated_count
  end

  def programme_has_high_unvaccinated_count?(programme)
    catch_up_year_groups =
      @draft_session.year_groups.select do |year_group|
        programme.is_catch_up?(year_group:)
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
