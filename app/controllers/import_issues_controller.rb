# frozen_string_literal: true

class ImportIssuesController < ApplicationController
  before_action :set_programme
  before_action :set_vaccination_record, only: %i[show update]
  before_action :set_form, only: %i[show update]

  layout "full"

  def index
    @import_issues = @programme.import_issues
  end

  def show
  end

  def update
    if @form.save
      redirect_to programme_import_issues_path(@programme),
                  flash: {
                    success: "Vaccination record updated"
                  }
    else
      render :show, status: :unprocessable_entity and return
    end
  end

  private

  def set_programme
    @programme =
      policy_scope(Programme)
        .active
        .includes(:immunisation_imports)
        .find(params[:programme_id])
  end

  def set_vaccination_record
    @vaccination_record = @programme.import_issues.find(params[:id])
  end

  def set_form
    apply_changes =
      params.dig(:immunisation_import_duplicate_form, :apply_changes)

    @form =
      ImmunisationImportDuplicateForm.new(
        vaccination_record: @vaccination_record,
        apply_changes:
      )
  end
end
