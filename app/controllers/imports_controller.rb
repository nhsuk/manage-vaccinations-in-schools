# frozen_string_literal: true

class ImportsController < ApplicationController
  include Pagy::Backend

  before_action :authorize_import
  skip_after_action :verify_policy_scoped

  helper_method :uploaded_files_view?

  layout "full"

  def index
    cohort_imports =
      policy_scope(CohortImport).status_for_uploaded_files.select(
        :id,
        :created_at,
        "'CohortImport' as model_name"
      )
    class_imports =
      policy_scope(ClassImport).status_for_uploaded_files.select(
        :id,
        :created_at,
        "'ClassImport' as model_name"
      )
    immunisation_imports =
      policy_scope(ImmunisationImport).status_for_uploaded_files.select(
        :id,
        :created_at,
        "'ImmunisationImport' as model_name"
      )

    mixnmatch_imports =
      cohort_imports
        .union(class_imports)
        .union(immunisation_imports)
        .order("created_at DESC")

    @pagy, @mixnmatch_imports = pagy(mixnmatch_imports, limit: 20)

    @active = :uploaded
  end

  def records
    cohort_imports =
      policy_scope(CohortImport).status_for_imported_records.select(
        :id,
        :created_at,
        "'CohortImport' as model_name"
      )
    class_imports =
      policy_scope(ClassImport).status_for_imported_records.select(
        :id,
        :created_at,
        "'ClassImport' as model_name"
      )
    immunisation_imports =
      policy_scope(ImmunisationImport).status_for_imported_records.select(
        :id,
        :created_at,
        "'ImmunisationImport' as model_name"
      )

    mixnmatch_imports =
      cohort_imports
        .union(class_imports)
        .union(immunisation_imports)
        .order("created_at DESC")

    @pagy, @mixnmatch_imports = pagy(mixnmatch_imports)

    @active = :imported
    render :index
  end

  def create
    if current_team.has_national_reporting_access?
      redirect_to new_immunisation_import_path
    else
      DraftImport.new(request_session: session, current_user:).clear!
      redirect_to draft_import_path(Wicked::FIRST_STEP)
    end
  end

  private

  def authorize_import
    authorize :import
  end

  def uploaded_files_view?
    @active == :uploaded
  end
end
