# frozen_string_literal: true

class AddAcademicYearToSessions < ActiveRecord::Migration[7.2]
  def up
    add_column :sessions, :academic_year, :integer

    Session.all.find_each do |session|
      session.update!(
        academic_year:
          (session.dates.map(&:value).min || Date.current).academic_year
      )
    end

    change_column_null :sessions, :academic_year, false
  end

  def down
    remove_column :sessions, :academic_year
  end
end
