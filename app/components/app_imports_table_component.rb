# frozen_string_literal: true

class AppImportsTableComponent < ViewComponent::Base
  def initialize(organisation:, programme:)
    super

    @organisation = organisation
    @programme = programme
  end

  def render?
    imports.present?
  end

  private

  attr_reader :organisation, :programme

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
      .where(organisation:, session: programme.sessions)
      .left_outer_joins(:patients)
      .includes(:uploaded_by, session: :location)
      .group("class_imports.id")
  end

  def cohort_import_records
    CohortImport
      .select("cohort_imports.*", "COUNT(patients.id) AS record_count")
      .where(organisation:, programme:)
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
      .where(organisation:, programme:)
      .left_outer_joins(:vaccination_records)
      .includes(:uploaded_by)
      .group("immunisation_imports.id")
  end

  def path(programme, import)
    if import.is_a?(ClassImport)
      session_class_import_path(import.session, import)
    elsif import.is_a?(CohortImport)
      programme_cohort_import_path(programme, import)
    else
      programme_immunisation_import_path(programme, import)
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
end
