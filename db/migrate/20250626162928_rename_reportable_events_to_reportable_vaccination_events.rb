class RenameReportableEventsToReportableVaccinationEvents < ActiveRecord::Migration[8.0]
  def change
    rename_table :reportable_events, :reportable_vaccination_events
  end
end
