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

    def show
      @form = BulkRemoveParentsForm.new(consents: @consents)
    end

    def create
      @form =
        BulkRemoveParentsForm.new(
          consents: @consents,
          remove_option: params.dig(:bulk_remove_parents_form, :remove_option)
        )

      if @form.valid?
        if @form.remove_option == "unconsented"
          @import.destroy_parent_relationships_without_consent!(@consents)
          success_flash_text = t(".show.options.unconsented_only.success_flash")
        else
          @import.destroy_parent_relationships_and_invalidate_consents!(
            current_user,
            @consents
          )
          success_flash_text = t(".show.options.all.success_flash")
        end

        redirect_to imports_path, flash: { success: success_flash_text }
      else
        render :show, status: :unprocessable_content
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
          .includes(:consents)
          .includes(:parent_relationships)
          .flat_map(&:consents)
          .filter { parent_relationships.include?(it.parent_relationship) }
          .reject(&:invalidated?)

      @pagy, @consents = pagy_array(consents)
    end
  end
end
