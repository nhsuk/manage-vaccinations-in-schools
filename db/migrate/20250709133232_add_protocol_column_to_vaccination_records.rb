# frozen_string_literal: true

class AddProtocolColumnToVaccinationRecords < ActiveRecord::Migration[8.0]
  def up
    add_column :vaccination_records, :protocol, :integer

    reversible { |dir| dir.up { VaccinationRecord.update_all(protocol: :pgd) } }
  end
end
