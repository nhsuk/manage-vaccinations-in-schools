# frozen_string_literal: true

class AddNotifyParentsToVaccinationRecords < ActiveRecord::Migration[8.0]
  def up
    add_column :vaccination_records, :notify_parents, :boolean

    VaccinationRecord.recorded_in_service.find_each do |vaccination_record|
      notify_parents_value = vaccination_record.send(:notify_parents?)
      vaccination_record.update_column(:notify_parents, notify_parents_value)
    end
  end

  def down
    remove_column :vaccination_records, :notify_parents
  end
end
