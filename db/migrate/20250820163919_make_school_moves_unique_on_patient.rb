# frozen_string_literal: true

class MakeSchoolMovesUniqueOnPatient < ActiveRecord::Migration[8.0]
  def change
    change_table :school_moves, bulk: true do |t|
      t.remove_index %i[patient_id home_educated team_id], unique: true
      t.remove_index %i[patient_id school_id], unique: true
    end

    reversible do |dir|
      dir.up do
        patient_ids_with_multiple_school_moves =
          SchoolMove
            .group(:patient_id)
            .having("COUNT(*) > 1")
            .pluck(:patient_id)

        patient_ids_with_multiple_school_moves.each do |patient_id|
          newest_school_move_id =
            SchoolMove.where(patient_id:).order(:created_at).last.id
          SchoolMove
            .where(patient_id:)
            .where.not(id: newest_school_move_id)
            .delete_all
        end
      end
    end

    add_index :school_moves, :patient_id, unique: true
  end
end
