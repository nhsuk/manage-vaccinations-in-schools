# frozen_string_literal: true

class CohortImportsController < ApplicationController
  include Pagy::Backend

  before_action :set_draft_import, only: %i[new create]
  before_action :set_cohort_import, only: %i[show update]

  skip_after_action :verify_policy_scoped, only: %i[new create]

  def new
    @cohort_import = CohortImport.new(team: current_team)
  end

  def create
    @cohort_import =
      CohortImport.new(
        academic_year: @academic_year,
        team: current_team,
        uploaded_by: current_user,
        **cohort_import_params
      )

    @cohort_import.load_data!
    if @cohort_import.invalid?
      render :new, status: :unprocessable_content and return
    end

    @cohort_import.save!

    if @cohort_import.slow?
      ProcessImportJob.perform_later(@cohort_import)
      redirect_to imports_path, flash: { success: "Import processing started" }
    else
      ProcessImportJob.perform_now(@cohort_import)
      redirect_to cohort_import_path(@cohort_import)
    end
  end

  def show
    @cohort_import.load_serialized_errors! if @cohort_import.rows_are_invalid?

    @pagy, @patients = pagy(@cohort_import.patients.includes(:school))

    @duplicates = @cohort_import.patients.with_pending_changes.distinct

    @issues_text =
      @duplicates.each_with_object({}) do |patient, hash|
        changeset = @cohort_import.changesets.find_by(patient_id: patient.id)

        issue_groups =
          helpers.issue_categories_for(patient.pending_changes.keys)

        hash[patient.full_name] = if changeset&.matched_on_nhs_number
          "Matched on NHS number. #{issue_groups.to_sentence.capitalize}" +
            (issue_groups.size == 1 ? " does not match." : " do not match.")
        else
          "Possible match found. Review and confirm."
        end
      end

    @nhs_discrepancies = @cohort_import.changesets.nhs_number_discrepancies

    render template: "imports/show",
           layout: "full",
           locals: {
             import: @cohort_import
           }
  end

  def update
    @cohort_import.process!

    redirect_to cohort_import_path(@cohort_import)
  end

  private

  def set_draft_import
    @draft_import = DraftImport.new(request_session: session, current_user:)
    @academic_year = @draft_import.academic_year
  end

  def set_cohort_import
    @cohort_import = policy_scope(CohortImport).find(params[:id])
    @academic_year = @cohort_import.academic_year
  end

  def cohort_import_params
    params.fetch(:cohort_import, {}).permit(:csv)
  end
end
