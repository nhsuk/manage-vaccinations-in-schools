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

  def imports
    @imports ||=
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
        .to_a
  end
end
