# frozen_string_literal: true

class AppImportTablesComponent < ViewComponent::Base
  def initialize(team:, programme:)
    super

    @team = team
    @programme = programme
  end

  def render?
    imports.present?
  end

  private

  attr_reader :team, :programme

  def imports
    @imports ||=
      (
        class_import_records + cohort_import_records +
          immunisation_import_records
      ).sort_by(&:created_at).reverse
  end

  def completed_imports
    @completed_imports ||= imports.select(&:recorded?)
  end

  def incomplete_imports
    @incomplete_imports ||= imports.reject(&:recorded?)
  end

  def class_import_records
    ClassImport
      .select("class_imports.*", "COUNT(patients.id) AS record_count")
      .where(team:, session: programme.sessions)
      .left_outer_joins(:patients)
      .includes(:uploaded_by)
      .group("class_imports.id")
      .strict_loading
  end

  def cohort_import_records
    CohortImport
      .select("cohort_imports.*", "COUNT(patients.id) AS record_count")
      .where(team:, programme:)
      .left_outer_joins(:patients)
      .includes(:uploaded_by)
      .group("cohort_imports.id")
      .strict_loading
  end

  def immunisation_import_records
    ImmunisationImport
      .select(
        "immunisation_imports.*",
        "COUNT(vaccination_records.id) AS record_count"
      )
      .where(team:, programme:)
      .left_outer_joins(:vaccination_records)
      .includes(:uploaded_by)
      .group("immunisation_imports.id")
      .strict_loading
  end

  def path(programme, import)
    if import.recorded?
      if import.is_a?(ClassImport)
        session_class_import_path(import.session_id, import)
      elsif import.is_a?(CohortImport)
        programme_cohort_import_path(programme, import)
      else
        programme_immunisation_import_path(programme, import)
      end
    elsif import.is_a?(ClassImport)
      edit_session_class_import_path(import.session_id, import)
    elsif import.is_a?(CohortImport)
      edit_programme_cohort_import_path(programme, import)
    else
      edit_programme_immunisation_import_path(programme, import)
    end
  end

  def record_type(import)
    if import.is_a?(ClassImport)
      "Class list"
    elsif import.is_a?(CohortImport)
      "Child records"
    else
      "Vaccination records"
    end
  end

  def status_text(import)
    {
      "pending_import" => "Processing",
      "processed" => "Ready",
      "rows_are_invalid" => "Failed"
    }[
      import.status
    ]
  end

  def status_color(import)
    {
      "pending_import" => "grey",
      "processed" => "green",
      "rows_are_invalid" => "red"
    }[
      import.status
    ]
  end
end
