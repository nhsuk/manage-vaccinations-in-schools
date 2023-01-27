class FHIRVaccinationEvent
  def initialize(entry)
    @entry = entry
  end

  def occurrence_date_time
    Time.zone.parse(@entry.occurrenceDateTime)
  end

  def vaccination
    @entry.extension.first.valueCodeableConcept.coding.first.display
  end

  def brand
    @entry.vaccineCode.coding.first.display
  end

  def batch
    @entry.lotNumber
  end
end
