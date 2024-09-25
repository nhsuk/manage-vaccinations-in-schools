# frozen_string_literal: true

class RemoveDateFromSessions < ActiveRecord::Migration[7.2]
  def up
    Session.all.find_each do |session|
      next if (date = session.date).nil?
      session.dates.create!(value: date)
    end

    remove_column :sessions, :date
  end

  def down
    add_column :sessions, :date, :date
  end
end
