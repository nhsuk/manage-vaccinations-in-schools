# frozen_string_literal: true

class ClassImportsController < ApplicationController
  include Pagy::Backend

  before_action :set_draft_import, only: %i[new create]
  before_action :set_class_import, only: %i[show update]

  skip_after_action :verify_policy_scoped, only: %i[new create]

  def new
    @class_import = ClassImport.new(team: current_team)
  end

  def create
    @class_import =
      ClassImport.new(
        academic_year: @academic_year,
        location: @location,
        team: current_team,
        uploaded_by: current_user,
        year_groups: @draft_import.year_groups,
        **class_import_params
      )

    @class_import.load_data!
    if @class_import.invalid?
      render :new, status: :unprocessable_content and return
    end

    @class_import.save!

    ProcessImportJob.perform_later(@class_import)
    redirect_to imports_path, flash: { success: "Import processing started" }
  end

  def show
    if @class_import.rows_are_invalid? || @class_import.changesets_are_invalid?
      @class_import.load_serialized_errors!
    end

    @pagy, @patients = pagy(@class_import.patients.includes(:school))

    @duplicates =
      @patients.with_pending_changes_for_team(team: current_team).distinct

    @issues_text =
      @duplicates.each_with_object({}) do |patient, hash|
        changeset = @class_import.changesets.find_by(patient_id: patient.id)

        issue_groups =
          helpers.issue_categories_for(patient.pending_changes.keys)

        hash[patient.full_name] = if changeset&.matched_on_nhs_number
          "Matched on NHS number. #{issue_groups.to_sentence.capitalize}" +
            (issue_groups.size == 1 ? " does not match." : " do not match.")
        else
          "Possible match found. Review and confirm."
        end
      end

    @nhs_discrepancies = @class_import.changesets.nhs_number_discrepancies

    render template: "imports/show",
           layout: "full",
           locals: {
             import: @class_import
           }
  end

  def update
    @class_import.process!

    redirect_to class_import_path(@class_import)
  end

  private

  def set_draft_import
    @draft_import = DraftImport.new(request_session: session, current_user:)
    @location = @draft_import.location
    @academic_year = @draft_import.academic_year
  end

  def set_class_import
    @class_import =
      policy_scope(ClassImport).includes(:location).find(params[:id])
    @location = @class_import.location
    @academic_year = @class_import.academic_year
  end

  def class_import_params
    params.fetch(:class_import, {}).permit(:csv)
  end
end
