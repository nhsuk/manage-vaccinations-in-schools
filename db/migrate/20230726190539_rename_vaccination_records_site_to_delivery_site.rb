# frozen_string_literal: true

class RenameVaccinationRecordsSiteToDeliverySite < ActiveRecord::Migration[7.0]
  def change
    rename_column :vaccination_records, :site, :delivery_site
  end
end
