# frozen_string_literal: true

class AppImportsTableComponent < ViewComponent::Base
  def initialize(programme)
    super

    @programme = programme
  end

  def render?
    imports.present?
  end

  private

  attr_reader :programme
  delegate :team, to: :programme

  def imports
    @imports ||=
      (cohort_import_records + immunisation_import_records).sort_by do
        _1[:created_at]
      end
  end

  def cohort_import_records
    CohortImport
      .select("cohort_imports.*", "COUNT(patients.id) AS record_count")
      .where(team:)
      .left_outer_joins(:patients)
      .includes(:uploaded_by)
      .merge(Patient.recorded)
      .group("cohort_imports.id")
      .strict_loading
      .map do
        {
          created_at: _1.created_at,
          path: programme_cohort_import_path(@programme, _1),
          record_count: _1.record_count,
          record_type: "Child records",
          uploaded_by: _1.uploaded_by
        }
      end
  end

  def immunisation_import_records
    ImmunisationImport
      .select(
        "immunisation_imports.*",
        "COUNT(vaccination_records.id) AS record_count"
      )
      .where(programme:)
      .left_outer_joins(:vaccination_records)
      .includes(:uploaded_by)
      .merge(VaccinationRecord.recorded)
      .group("immunisation_imports.id")
      .strict_loading
      .map do
        {
          created_at: _1.created_at,
          path: programme_immunisation_import_path(@programme, _1),
          record_count: _1.record_count,
          record_type: "Vaccination records",
          uploaded_by: _1.uploaded_by
        }
      end
  end
end
