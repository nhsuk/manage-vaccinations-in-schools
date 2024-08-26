# frozen_string_literal: true

class AppVaccinationRecordTableComponent < ViewComponent::Base
  def initialize(vaccination_records, new_records: false)
    super

    @vaccination_records = vaccination_records
    @new_records = new_records
  end

  private

  attr_reader :vaccination_records, :new_records

  def heading
    pluralize(
      vaccination_records.count,
      new_records ? "new vaccination record" : "vaccination record"
    )
  end
end
