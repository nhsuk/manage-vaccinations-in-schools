# frozen_string_literal: true

class UpdateGillickAssessments < ActiveRecord::Migration[7.2]
  def up
    GillickAssessment.where(recorded_at: nil).delete_all

    change_table :gillick_assessments, bulk: true do |t|
      t.remove :recorded_at, type: :datetime
      t.remove :location_name, type: :string
      t.change_default :notes, ""
      t.change_null :notes, false, ""
      t.rename :assessor_user_id, :performed_by_user_id

      t.remove_index :patient_session_id
      t.index :patient_session_id, unique: true

      t.boolean :knows_vaccination
      t.boolean :knows_disease
      t.boolean :knows_consequences
      t.boolean :knows_delivery
      t.boolean :knows_side_effects
    end

    GillickAssessment.where(gillick_competent: true).update_all(
      knows_vaccination: true,
      knows_disease: true,
      knows_consequences: true,
      knows_delivery: true,
      knows_side_effects: true
    )

    GillickAssessment.where(gillick_competent: [nil, false]).update_all(
      knows_vaccination: false,
      knows_disease: false,
      knows_consequences: false,
      knows_delivery: false,
      knows_side_effects: false
    )

    change_table :gillick_assessments, bulk: true do |t|
      t.remove :gillick_competent, type: :boolean

      t.change_null :knows_vaccination, false
      t.change_null :knows_disease, false
      t.change_null :knows_consequences, false
      t.change_null :knows_delivery, false
      t.change_null :knows_side_effects, false
    end
  end

  # down not provided as it's difficult to reverse from this
end
