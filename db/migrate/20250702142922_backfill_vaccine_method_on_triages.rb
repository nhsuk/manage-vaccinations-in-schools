# frozen_string_literal: true

class BackfillVaccineMethodOnTriages < ActiveRecord::Migration[8.0]
  def up
    injection_value = Triage.vaccine_methods.fetch("injection")
    non_flu_programme_ids = Programme.where.not(type: "flu").pluck(:id)

    Triage
      .where(programme_id: non_flu_programme_ids)
      .where(status: "safe_to_vaccinate")
      .where(vaccine_method: nil)
      .update_all(vaccine_method: injection_value)
  end

  def down
    Triage.update_all(vaccine_method: nil)
  end
end
