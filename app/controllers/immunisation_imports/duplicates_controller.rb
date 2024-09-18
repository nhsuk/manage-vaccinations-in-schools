# frozen_string_literal: true

class ImmunisationImports::DuplicatesController < ApplicationController
  before_action :set_programme
  before_action :set_immunisation_import
  before_action :set_vaccination_record
  before_action :set_patient
  before_action :set_form

  def show
    render layout: "full"
  end

  def update
    if @form.save
      redirect_to edit_programme_immunisation_import_path(
                    @programme,
                    @immunisation_import
                  ),
                  flash: {
                    success: "Vaccination record updated"
                  }
    else
      render :show, status: :unprocessable_entity, layout: "full" and return
    end
  end

  private

  def set_programme
    @programme =
      policy_scope(Programme).includes(:immunisation_imports).find(
        params[:programme_id]
      )
  end

  def set_immunisation_import
    @immunisation_import =
      @programme.immunisation_imports.find(params[:immunisation_import_id])
  end

  def set_vaccination_record
    @vaccination_record =
      @immunisation_import.vaccination_records.find(params[:id])
  end

  def set_patient
    @patient = @vaccination_record.patient
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
