class FHIRVaccinationEvent
  DISPLAY_NAMES = {
    "734152003" => {
      medium: "HPV vaccine (12 to 13 years)",
      short: "HPV"
    }
  }.freeze

  def initialize(entry)
    @entry = entry
  end

  def occurrence_date_time
    Time.zone.parse(@entry.occurrenceDateTime)
  end

  def medium_display_name
    DISPLAY_NAMES[
      @entry.extension.first.valueCodeableConcept.coding.first.code
    ][
      :medium
    ]
  end

  def short_display_name
    DISPLAY_NAMES[
      @entry.extension.first.valueCodeableConcept.coding.first.code
    ][
      :short
    ]
  end

  def brand
    @entry.vaccineCode.coding.first.display
  end

  def batch
    @entry.lotNumber
  end
end
