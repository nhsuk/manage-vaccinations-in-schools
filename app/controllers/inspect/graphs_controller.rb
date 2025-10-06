# frozen_string_literal: true

module Inspect
  class GraphsController < ApplicationController
    include InspectAuthenticationConcern

    skip_before_action :ensure_team_is_selected
    skip_after_action :verify_policy_scoped
    before_action :ensure_ops_tools_feature_enabled
    after_action :record_access_log_entry

    layout "full"

    SHOW_PII_BY_DEFAULT = false

    def show
      @primary_type = safe_get_primary_type
      if @primary_type.nil?
        render plain:
                 "You don't have permission to view object type: #{params[:object_type].to_s.downcase.singularize}",
               status: :bad_request and return
      end
      @primary_id = params[:object_id]

      # Set default relationships when loading a page for the first time
      if params[:relationships].blank? &&
           GraphRecords::DEFAULT_TRAVERSALS.key?(@primary_type)
        default_rels = GraphRecords::DEFAULT_TRAVERSALS[@primary_type] || {}

        new_params = params.to_unsafe_h.merge("relationships" => default_rels)
        redirect_to inspect_path(new_params) and return
      end

      @object = @primary_type.to_s.classify.constantize.find(@primary_id)

      @traversals_config = build_traversals_config
      @graph_params = build_graph_params
      set_pii_settings

      @graph_record =
        GraphRecords.new(
          traversals_config: @traversals_config,
          primary_type: @primary_type,
          clickable: true,
          show_pii: @show_pii
        )
      @mermaid = @graph_record.graph(**@graph_params).join("\n")
    end

    private

    def set_pii_settings
      @user_is_allowed_to_access_pii = user_is_support_with_pii_access?
      @show_pii =
        @user_is_allowed_to_access_pii &&
          (params[:show_pii] || SHOW_PII_BY_DEFAULT)
    end

    def build_traversals_config
      traversals_config = {}
      to_process = Set.new([@primary_type])
      processed = Set.new

      # Process types until we've explored all connected relationships
      while (type = to_process.first)
        to_process.delete(type)
        processed.add(type)

        selected_rels =
          Array(params.dig(:relationships, type)).reject(&:blank?).map(&:to_sym)

        traversals_config[type] = selected_rels

        # Add target types to process queue
        klass = type.to_s.classify.constantize
        selected_rels.each do |rel|
          association = klass.reflect_on_association(rel)
          next unless association

          target_type = association.klass.name.underscore.to_sym
          to_process.add(target_type) unless processed.include?(target_type)
        end
      end

      traversals_config
    end

    def build_graph_params
      graph_params = { @primary_type => [@object.id] }

      if params[:additional_ids].present?
        params[:additional_ids].each do |type, ids_string|
          next if ids_string.blank?
          additional_ids = ids_string.split(",").map { |s| s.strip.to_i }
          next unless additional_ids.any?
          type_sym = type.to_sym
          graph_params[type_sym] ||= []
          graph_params[type_sym].concat(additional_ids)
        end
      end

      graph_params
    end

    def safe_get_primary_type
      singular_type = params[:object_type].downcase.singularize
      return nil unless GraphRecords::ALLOWED_TYPES.include?(singular_type)
      singular_type.to_sym
    end

    def pii_accessed?
      return false unless @show_pii

      build_traversals_config.any? do |from_type, rels|
        GraphRecords::EXTRA_DETAIL_WHITELIST_WITH_PII.key?(
          from_type.name.underscore.to_sym
        ) ||
          rels.any? do |rel|
            from_class = from_type.to_s.classify.constantize
            to_type = from_class.reflect_on_association(rel)&.klass
            to_type &&
              GraphRecords::EXTRA_DETAIL_WHITELIST_WITH_PII.key?(
                to_type.name.underscore.to_sym
              )
          end
      end
    end

    def record_access_log_entry
      if pii_accessed?
        @graph_record.patients_with_pii_in_graph.each do |patient|
          request_details = build_request_details
          additional_ids =
            params[:additional_ids]
              &.to_unsafe_h
              &.each_with_object({}) do |(type, ids_string), result|
                result[type.to_sym] = ids_string if ids_string.present?
              end

          patient.access_log_entries.create!(
            user: current_user,
            controller: "graph",
            action: "show_pii",
            request_details: {
              primary_type: @primary_type,
              primary_id: @primary_id,
              additional_ids: additional_ids.presence,
              visible_fields: request_details
            }
          )
        end
      end
    end

    def build_request_details
      build_traversals_config.each_with_object(
        {}
      ) do |(_, relationships), details|
        relationships.each { |rel| add_fields_to_details(details, rel) }
      end
    end

    def add_fields_to_details(details, type_sym)
      fields = []
      fields.concat(GraphRecords::DETAIL_WHITELIST[type_sym] || [])
      fields.concat(
        GraphRecords::EXTRA_DETAIL_WHITELIST_WITH_PII[type_sym] || []
      )
      details[type_sym] = fields.uniq if fields.any?
    end
  end
end
