# frozen_string_literal: true

class RemoveImmunisationImportCSVJob < ApplicationJob
  queue_as :default

  def perform
    ImmunisationImport
      .csv_not_removed
      .where("created_at < ?", Time.zone.now - 30.days)
      .find_each(&:remove!)
  end
end
