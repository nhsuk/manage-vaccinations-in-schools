# frozen_string_literal: true

class DataMigration::SetSessionDates
  def call
    Session
      .where(dates: nil)
      .includes(:session_dates)
      .find_each { |session| session.update_columns(dates: session.dates.sort) }
  end

  def self.call(...) = new(...).call

  private_class_method :new
end
