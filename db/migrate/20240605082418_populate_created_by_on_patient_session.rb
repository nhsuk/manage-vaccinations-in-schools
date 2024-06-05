class PopulateCreatedByOnPatientSession < ActiveRecord::Migration[7.1]
  def up
    PatientSession.find_each do |ps|
      ps.update(created_by: ps.audits.find { _1.action == "create" }.user)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
