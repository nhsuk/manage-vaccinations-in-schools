# frozen_string_literal: true

class AddOrganisationToVaccinationRecords < ActiveRecord::Migration[8.0]
  def up
    add_column :vaccination_records, :performed_ods_code, :string

    VaccinationRecord
      .includes(:organisation)
      .find_each do |vaccination_record|
        vaccination_record.update_column(
          :performed_ods_code,
          vaccination_record.organisation.ods_code
        )
      end

    change_column_null :vaccination_records, :performed_ods_code, false
  end

  def down
    remove_column :vaccination_records, :performed_ods_code
  end
end
