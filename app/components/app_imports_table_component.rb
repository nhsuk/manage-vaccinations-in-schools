# frozen_string_literal: true

class AppImportsTableComponent < ViewComponent::Base
  def initialize(team:, uploaded_files: true)
    @team = team
    @uploaded_files = uploaded_files
  end

  def render? = imports.present?

  private

  attr_reader :team

  delegate :govuk_table, to: :helpers

  def imports
    @imports ||=
      if @uploaded_files
        (
          class_import_records.status_for_uploaded_files +
            cohort_import_records.status_for_uploaded_files +
            immunisation_import_records.status_for_uploaded_files
        ).sort_by(&:created_at).reverse
      else
        (
          class_import_records.status_for_imported_records +
            cohort_import_records.status_for_imported_records +
            immunisation_import_records.status_for_imported_records
        ).sort_by(&:created_at).reverse
      end
  end

  def class_import_records
    ClassImport
      .select("class_imports.*", "COUNT(patients.id) AS record_count")
      .where(team:)
      .left_outer_joins(:patients)
      .includes(:location, :uploaded_by)
      .group("class_imports.id")
  end

  def cohort_import_records
    CohortImport
      .select("cohort_imports.*", "COUNT(patients.id) AS record_count")
      .where(team:)
      .left_outer_joins(:patients)
      .includes(:uploaded_by)
      .group("cohort_imports.id")
  end

  def immunisation_import_records
    ImmunisationImport
      .select(
        "immunisation_imports.*",
        "COUNT(vaccination_records.id) AS record_count"
      )
      .where(team:)
      .left_outer_joins(:vaccination_records)
      .includes(:uploaded_by)
      .group("immunisation_imports.id")
  end

  def path(import)
    if import.is_a?(ClassImport)
      class_import_path(import)
    elsif import.is_a?(CohortImport)
      cohort_import_path(import)
    else
      immunisation_import_path(import)
    end
  end

  def record_type(import)
    if import.is_a?(ClassImport)
      "Class list records"
    elsif import.is_a?(CohortImport)
      "Child records"
    else
      "Vaccination records"
    end
  end
end
