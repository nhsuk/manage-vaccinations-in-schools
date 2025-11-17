# frozen_string_literal: true

class CohortImportsController < ApplicationController
  include Pagy::Backend

  before_action :set_draft_import, only: %i[new create]
  before_action :set_cohort_import,
                only: %i[show update approve cancel re_review imported_records]
  before_action :set_review_records, only: %i[re_review imported_records]

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

    ProcessImportJob.perform_later(@cohort_import)
    redirect_to imports_path, flash: { success: "Import processing started" }
  end

  def show
    if @cohort_import.rows_are_invalid? ||
         @cohort_import.changesets_are_invalid?
      @cohort_import.load_serialized_errors!
    end

    set_review_records if @cohort_import.in_review?

    if @cohort_import.in_re_review?
      redirect_to re_review_cohort_import_path(@cohort_import) and return
    end

    if @cohort_import.processed? || @cohort_import.partially_processed?
      @pagy, @patients = pagy(@cohort_import.patients.includes(:school))

      @duplicates =
        @patients.with_pending_changes_for_team(team: current_team).distinct

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

      @cancelled = @cohort_import.changesets.from_file.cancelled
    end

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

  def re_review
    render template: "imports/re_review",
           layout: "full",
           locals: {
             import: @cohort_import
           }
  end

  def imported_records
    render template: "imports/imported_records",
           layout: "full",
           locals: {
             import: @cohort_import
           }
  end

  def approve
    @cohort_import.reviewed_by_user_ids << current_user.id
    @cohort_import.reviewed_at << Time.zone.now
    @cohort_import.committing!

    @cohort_import
      .changesets
      .from_file
      .ready_for_review
      .in_batches(of: 100) do |batch|
        CommitPatientChangesetsJob.perform_async(batch.ids)
      end

    @cohort_import.changesets.from_file.ready_for_review.each(&:committing!)

    redirect_to imports_path, flash: { info: "Import started" }
  end

  def cancel
    @cohort_import.reviewed_by_user_ids << current_user.id
    @cohort_import.reviewed_at << Time.zone.now

    # some changesets were processed after first review, but the second review was cancelled
    if @cohort_import.changesets.processed.any?
      @cohort_import.update_columns(
        processed_at: Time.zone.now,
        status: :partially_processed
      )
      @cohort_import.changesets.ready_for_review.find_each(&:cancelled!)

      @cohort_import.postprocess_rows!

      redirect_to imports_path, flash: { success: "Import partially completed" }
    else
      @cohort_import.update!(status: :cancelled)
      @cohort_import.changesets.each(&:cancelled!)

      redirect_to imports_path, flash: { success: "Import cancelled" }
    end
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

  def set_review_records
    @pagy, @patients = pagy(@cohort_import.patients.includes(:school))
    @new_records = @cohort_import.changesets.ready_for_review.new_patient
    @auto_matched_records =
      @cohort_import.changesets.ready_for_review.auto_match
    @import_issues = @cohort_import.changesets.ready_for_review.import_issue
    @school_moves = @cohort_import.changesets.ready_for_review.with_school_moves
    @re_review =
      @new_records + @auto_matched_records + @import_issues + @school_moves
  end
end
