# frozen_string_literal: true

class AppImportsTableComponent < ViewComponent::Base
  def initialize(organisation:)
    super

    @organisation = organisation
  end

  def render?
    imports.present?
  end

  private

  attr_reader :organisation

  def imports
    @imports ||=
      (
        class_import_records + cohort_import_records +
          immunisation_import_records
      ).sort_by(&:created_at).reverse
  end

  def class_import_records
    ClassImport
      .select("class_imports.*", "COUNT(patients.id) AS record_count")
      .where(organisation:)
      .left_outer_joins(:patients)
      .includes(:location, :uploaded_by)
      .group("class_imports.id")
  end

  def cohort_import_records
    CohortImport
      .select("cohort_imports.*", "COUNT(patients.id) AS record_count")
      .where(organisation:)
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
      .where(organisation:)
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
