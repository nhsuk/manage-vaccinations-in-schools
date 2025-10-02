# frozen_string_literal: true

class Inspect::Timeline::PatientsController < ApplicationController
  skip_after_action :verify_policy_scoped
  skip_before_action :authenticate_user!
  before_action :set_patient

  layout "full"

  SHOW_PII = false

  DEFAULT_EVENT_NAMES = %w[
    consents
    school_moves
    school_move_log_entries
    audits
    sessions
    triages
    vaccination_records
    class_imports
    cohort_imports
  ].freeze

  def show
    @show_pii = params[:show_pii] || SHOW_PII

    params.reverse_merge!(event_names: DEFAULT_EVENT_NAMES)
    params[:audit_config] ||= {}

    event_names = params[:event_names]
    compare_option = params[:compare_option] || nil

    if params[:detail_config].blank?
      default_details = TimelineRecords::DEFAULT_DETAILS_CONFIG
      new_params = params.to_unsafe_h.merge("detail_config" => default_details)
      redirect_to inspect_timeline_patient_path(new_params) and return
    end

    audit_config = {
      include_associated_audits:
        params[:audit_config][:include_associated_audits],
      include_filtered_audit_changes:
        params[:audit_config][:include_filtered_audit_changes]
    }

    @patient_timeline =
      TimelineRecords.new(
        @patient,
        detail_config: build_details_config,
        audit_config: audit_config,
        show_pii: @show_pii
      ).load_timeline_events(event_names)

    @no_events_message = true if @patient_timeline.empty?

    @compare_patient = sample_patient(params[:compare_option]) if compare_option

    if @compare_patient == :invalid_patient
      @invalid_patient_id = true
    elsif @compare_patient
      @compare_patient_timeline =
        TimelineRecords.new(
          @compare_patient,
          detail_config: build_details_config,
          audit_config: audit_config
        ).load_timeline_events(event_names)

      @no_events_compare_message = true if @compare_patient_timeline.empty?
    end
  end

  private

  def set_patient
    @patient = Patient.find(params[:id])
    timeline = TimelineRecords.new(@patient)
    @patient_events = timeline.patient_events(@patient)
    @additional_events = timeline.additional_events(@patient)
  end

  # TODO: Fix so that a new comparison patient isn't sampled every time
  #       a filter option is changed and the page is reloaded.
  def sample_patient(compare_option)
    return nil if compare_option.blank? || compare_option == "on"

    case compare_option
    when "class_import"
      class_import = params[:compare_option_class_import]
      class_import.patients.where.not(id: @patient.id).sample
    when "cohort_import"
      cohort_import = params[:compare_option_cohort_import]
      cohort_import.patients.where.not(id: @patient.id).sample
    when "session"
      session = Session.find(params[:compare_option_session])
      session.patients.where.not(id: @patient.id).sample
    when "manual_entry"
      begin
        Patient.find(params[:manual_patient_id])
      rescue ActiveRecord::RecordNotFound
        :invalid_patient
      end
    else
      raise ArgumentError, <<~MESSAGE
      Invalid patient comparison option: #{compare_option}.
      Supported options are: class_import, cohort_import, session, manual_entry
    MESSAGE
    end
  end

  def build_details_config
    details_params = params[:detail_config] || {}
    details_params = details_params.to_unsafe_h unless details_params.is_a?(
      Hash
    )

    details_params.each_with_object({}) do |(event_type, fields), hash|
      selected_fields = Array(fields).reject(&:blank?).map(&:to_sym)
      hash[event_type.to_sym] = selected_fields
    end
  end
end
