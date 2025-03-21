# frozen_string_literal: true

module Inspect
  module Timeline
    class PatientsController < ApplicationController
      skip_after_action :verify_policy_scoped
      skip_before_action :authenticate_user!
      before_action :set_patient

      layout "full"

      DEFAULT_EVENT_NAMES = [
        'consents', 'school_moves', 'school_move_log_entries', 'audits',
        'patient_sessions', 'triages', 'vaccination_records', 'class_imports',
        'cohort_imports'
      ].freeze

      def set_patient
        @patient = Patient.find(params[:id])
        timeline = TimelineRecords.new(@patient.id)
        @patient_events = timeline.patient_events(@patient)
        @additional_events = timeline.additional_events(@patient)
      end

      #TODO: Fix so that new patient isn't generated verytime a new option is seletced on filters
      def sample_patient(compare_option)
        case compare_option
        when 'class_import'
          class_import = params[:compare_option_class_import]
          Patient.joins(:class_imports)
            .where(class_imports: { id: class_import.id })
            .where.not(id: @patient.id)
            .sample
        when 'cohort_import'
          cohort_import = params[:compare_option_cohort_import]
          Patient.joins(:cohort_imports)
            .where(cohort_imports: { id: cohort_import.id })
            .where.not(id: @patient.id)
            .sample
        when 'session'
          session_id = params[:compare_option_session]
          Patient.joins(:patient_sessions)
          .where(patient_sessions: { session_id: session_id })
          .where.not(id: @patient.id)
          .sample
        when 'manual_entry'
          begin
            Patient.find(params[:manual_patient_id])
          rescue ActiveRecord::RecordNotFound
            :invalid_patient
          end
        end
      end

      def build_details_config
        details_params = params[:detail_config] || {}
        details_params = details_params.to_unsafe_h unless details_params.is_a?(Hash)
        
        details_params.each_with_object({}) do |(event_type, fields), hash|
          selected_fields = Array(fields).reject(&:blank?).map(&:to_sym)
          hash[event_type.to_sym] = selected_fields
        end
      end

      def show
        params.reverse_merge!(event_names: DEFAULT_EVENT_NAMES)
        params[:audit_config] ||= {}

        include_associated_audits = params.dig(:audit_config, :include_associated_audits) == true
        include_filtered_audit_changes = params.dig(:audit_config, :include_filtered_audit_changes) == true

        event_names = params[:event_names]
        compare_option = params[:compare_option] || nil
      
        if params[:detail_config].blank?
          default_details = TimelineRecords::DEFAULT_DETAILS_CONFIG
          new_params = params.to_unsafe_h.merge("detail_config" => default_details)
          redirect_to inspect_timeline_patient_path(new_params) and return
        end

        @patient_timeline = TimelineRecords
                            .new(
                              @patient.id, 
                              detail_config: build_details_config,
                              audit_config: { 
                                include_associated_audits: params[:audit_config][:include_associated_audits],
                                include_filtered_audit_changes: params[:audit_config][:include_filtered_audit_changes]
                              } 
                            )
        .load_grouped_events(event_names)

        if @patient_timeline.empty?
          @no_events_message = true
        end

        if compare_option
          @compare_patient = sample_patient(params[:compare_option])
        end

        if @compare_patient == :invalid_patient
          @invalid_patient_id = true
        elsif @compare_patient
          @compare_patient_timeline = TimelineRecords
                                        .new(
                                          @compare_patient.id, 
                                          detail_config: build_details_config,
                                          audit_config: { 
                                            include_associated_audits: params[:audit_config][:include_associated_audits],
                                            include_filtered_audit_changes: params[:audit_config][:include_filtered_audit_changes]
                                          } 
                                        )
                                        .load_grouped_events(event_names)

          if @compare_patient_timeline.empty?
            @no_events_compare_message = true
          end
        end
      end
    end
  end
end
