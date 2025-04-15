# frozen_string_literal: true

module Inspect
  class GraphsController < ApplicationController
    skip_after_action :verify_policy_scoped
    skip_before_action :authenticate_user!

    layout "full"

    SHOW_PII = false

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

      @mermaid =
        GraphRecords
          .new(
            traversals_config: @traversals_config,
            primary_type: @primary_type,
            clickable: true,
            show_pii: SHOW_PII
          )
          .graph(**@graph_params)
          .join("\n")
    end

    private

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
  end
end
