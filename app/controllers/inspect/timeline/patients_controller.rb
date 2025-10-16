# frozen_string_literal: true

class Inspect::Timeline::PatientsController < ApplicationController
  include InspectAuthenticationConcern

  skip_after_action :verify_policy_scoped
  before_action :ensure_ops_tools_feature_enabled
  before_action :set_patient

  layout "full"

  SHOW_PII_BY_DEFAULT = false

  def show
    set_pii_settings

    params[:audit_config] ||= {}

    compare_option = params[:compare_option] || nil

    # Set default values if none present
    if params[:detail_config].nil? && params[:event_names].nil? &&
         params[:show_pii].nil?
      default_details = TimelineRecords::DEFAULT_DETAILS_CONFIG
      default_events_selected =
        TimelineRecords::DEFAULT_DETAILS_CONFIG.keys.append(:audits)
      new_params =
        params.to_unsafe_h.merge(
          "detail_config" => default_details,
          "event_names" => default_events_selected
        )
      redirect_to inspect_timeline_patient_path(new_params) and return
    end

    audit_config = {
      include_associated_audits:
        params[:audit_config][:include_associated_audits],
      include_filtered_audit_changes:
        params[:audit_config][:include_filtered_audit_changes]
    }

    @compare_patient = sample_patient(params[:compare_option]) if compare_option
    @event_names = params[:event_names] || []

    record_access_log_entry

    @patient_timeline =
      TimelineRecords.new(
        @patient,
        detail_config: build_details_config,
        audit_config: audit_config,
        show_pii: @show_pii
      ).load_timeline_events(@event_names)

    @no_events_message = true if @patient_timeline.empty?

    if @compare_patient == :invalid_patient
      @invalid_patient_id = true
    elsif @compare_patient
      @compare_patient_timeline =
        TimelineRecords.new(
          @compare_patient,
          detail_config: build_details_config,
          audit_config: audit_config,
          show_pii: @show_pii
        ).load_timeline_events(@event_names)

      @no_events_compare_message = true if @compare_patient_timeline.empty?
    end
  end

  private

  def set_pii_settings
    @user_is_allowed_to_access_pii = user_is_support_with_pii_access?
    @show_pii =
      @user_is_allowed_to_access_pii &&
        (params[:show_pii] || SHOW_PII_BY_DEFAULT)
  end

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
      class_import = ClassImport.find(params[:compare_option_class_import])
      id = class_import.patients.where.not(id: @patient.id).pluck(:id).sample
      Patient.find(id)
    when "cohort_import"
      cohort_import = CohortImport.find(params[:compare_option_cohort_import])
      id = cohort_import.patients.where.not(id: @patient.id).pluck(:id).sample
      Patient.find(id)
    when "session"
      session = Session.find(params[:compare_option_session])
      id = session.patients.where.not(id: @patient.id).pluck(:id).sample
      Patient.find(id)
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

  def pii_accessed?
    return false unless @show_pii
    detail_config = build_details_config
    detail_config.any? do |event_type, selected_fields|
      pii_fields =
        TimelineRecords::AVAILABLE_DETAILS_CONFIG_PII[event_type] || []
      (selected_fields & pii_fields).any?
    end
  end

  def audit_pii_accessed?
    true if @show_pii && @event_names.include?("audits")
  end

  def record_access_log_entry
    return unless pii_accessed? || audit_pii_accessed?

    details_accessed =
      build_details_config.reverse_merge(
        @event_names.map { |key| [key.to_sym, []] }.to_h
      )
    details_accessed[:audits] = :accessed if details_accessed.key?(:audits)

    # Log access for main patient
    @patient.access_log_entries.create!(
      user: current_user,
      controller: "timeline",
      action: "show_pii",
      request_details: details_accessed
    )

    # Log access for compare patient if it exists and is valid
    if @compare_patient && @compare_patient != :invalid_patient
      @compare_patient.access_log_entries.create!(
        user: current_user,
        controller: "timeline",
        action: "show_pii",
        request_details: details_accessed
      )
    end
  end
end
