# frozen_string_literal: true

class AddLocationToClassLists < ActiveRecord::Migration[8.0]
  def up
    add_reference :class_imports, :location, foreign_key: true

    ClassImport.find_each do |class_import|
      session = Session.find(class_import.session_id)
      class_import.update_columns(location_id: session.location_id)
    end

    change_table :class_imports, bulk: true do |t|
      t.change_null :location_id, false
      t.remove_references :session
    end
  end

  def down
    add_reference :class_imports, :session, foreign_key: true

    ClassImport.find_each do |class_import|
      session =
        Session.find_by!(
          organisation_id: class_import.organisation_id,
          location_id: class_import.location_id,
          academic_year: AcademicYear.current
        )
      class_import.update_column(:session_id, session.id)
    end

    change_table :class_imports, bulk: true do |t|
      t.change_null :session_id, false
      t.remove :location_id
    end
  end
end
