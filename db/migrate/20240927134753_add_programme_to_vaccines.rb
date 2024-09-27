# frozen_string_literal: true

class AddProgrammeToVaccines < ActiveRecord::Migration[7.2]
  def up
    add_reference :vaccines, :programme, foreign_key: true

    Vaccine.all.find_each do |vaccine|
      vaccine.update!(
        programme: Programme.find_or_create_by!(type: vaccine.type)
      )
    end

    change_column_null :vaccines, :programme_id, false
  end

  def down
    remove_reference :vaccines, :programme
  end
end
