# frozen_string_literal: true

class AddProgrammeToVaccinationProgrammes < ActiveRecord::Migration[7.2]
  def up
    add_reference :vaccination_records, :programme, foreign_key: true

    VaccinationRecord.all.find_each do |vaccination_record|
      vaccination_record.update!(
        programme_id:
          (vaccination_record.session.programme || Programme.first).id
      )
    end

    change_column_null :vaccination_records, :programme_id, false
  end

  def down
    remove_reference :vaccination_records, :programme
  end
end
