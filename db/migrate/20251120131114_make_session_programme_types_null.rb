class MakeSessionProgrammeTypesNull < ActiveRecord::Migration[8.1]
  def change
    change_column_null :sessions, :programme_types, true
  end
end
