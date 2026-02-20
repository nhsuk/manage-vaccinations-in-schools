class ChangeVaccinationRecordsSourceCheckConstraint < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :vaccination_records, name: "source_check"

    add_check_constraint :vaccination_records,
                         "(session_id IS NULL AND source != 0 AND source != 5) OR " \
                           "(session_id IS NOT NULL AND (source = 0 OR source = 5))",
                         name: "source_check",
                         validate: false
  end

  def down
    remove_check_constraint :vaccination_records, name: "source_check"

    add_check_constraint :vaccination_records,
                         "(session_id IS NULL AND source != 0) OR " \
                           "(session_id IS NOT NULL AND source = 0)",
                         name: "source_check",
                         validate: false
  end
end
