# frozen_string_literal: true

class AddNationalReportingCutOffDateToTeam < ActiveRecord::Migration[8.1]
  def change
    add_column :teams, :national_reporting_cut_off_date, :date
  end
end
