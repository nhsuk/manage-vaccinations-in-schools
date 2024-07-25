# frozen_string_literal: true

class AppVaccinationRecordTableComponent < ViewComponent::Base
  def initialize(vaccination_records)
    super

    @vaccination_records = vaccination_records
  end

  private

  attr_reader :vaccination_records
end
