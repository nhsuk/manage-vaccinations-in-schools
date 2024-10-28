# frozen_string_literal: true

class ImportIssuesController < ApplicationController
  before_action :set_programme, :set_import_issues
  before_action :set_vaccination_record, only: %i[show update]
  before_action :set_form, only: %i[show update]

  layout "full"

  def index
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
    @programme = policy_scope(Programme).find_by!(type: params[:programme_type])
  end

  def set_import_issues
    @import_issues =
      policy_scope(VaccinationRecord)
        .where(programme: @programme)
        .with_pending_changes
        .distinct
        .includes(
          :batch,
          :location,
          :patient_session,
          session: :location,
          patient: %i[cohort school],
          vaccine: :programme
        )
        .strict_loading
  end

  def set_vaccination_record
    @vaccination_record = @import_issues.find(params[:id])
  end

  def set_form
    apply_changes = params.dig(:import_duplicate_form, :apply_changes)

    @form = ImportDuplicateForm.new(object: @vaccination_record, apply_changes:)
  end
end
