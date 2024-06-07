class PatientBelongsToParent < ActiveRecord::Migration[7.1]
  def change
    add_reference :patients, :parent, null: true, foreign_key: true
  end
end
