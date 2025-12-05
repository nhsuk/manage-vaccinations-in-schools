# frozen_string_literal: true

module Imports
  class BulkRemoveParentsController < ApplicationController
    include Pagy::Backend

    before_action :set_import
    before_action :set_consents
    skip_after_action :verify_policy_scoped

    IMPORT_CLASSES = {
      "class_import" => ClassImport,
      "cohort_import" => CohortImport
    }.freeze

    def new
      @form =
        BulkRemoveParentsForm.new(
          import: @import,
          consents: @consents,
          current_user:
        )
    end

    def create
      @form =
        BulkRemoveParentsForm.new(
          import: @import,
          consents: @consents,
          current_user:,
          remove_option: params.dig(:bulk_remove_parents_form, :remove_option)
        )

      if @form.save!
        redirect_to imports_path, flash: { success: success_flash_text }
      else
        render :new, status: :unprocessable_content
      end
    end

    private

    def set_import
      import_class = IMPORT_CLASSES[params[:import_type]]
      @import = import_class&.find(params[:import_id])
      raise ActiveRecord::RecordNotFound unless @import
    end

    def set_consents
      parent_relationships = @import.parent_relationships
      consents =
        @import
          .patients
          .includes(:consents, :parent_relationships)
          .flat_map(&:consents)
          .filter { parent_relationships.include?(it.parent_relationship) }
          .reject(&:invalidated?)

      @pagy, @consents = pagy_array(consents)
    end

    def success_flash_text
      if @form.remove_option == "unconsented_only"
        t(".success_flash.unconsented_only")
      else
        t(".success_flash.all")
      end
    end
  end
end
