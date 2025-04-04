# frozen_string_literal: true

class ClassImportRow < PatientImportRow
  validate :validate_address_postcode

  def initialize(data:, session:, year_groups:)
    super(data:, organisation: session.organisation, year_groups:)
    @school = session.location
  end

  private

  attr_reader :school

  def stage_registration?
    false
  end

  def school_move_source
    :class_list_import
  end

  def home_educated
    nil # false is used when school is unknown
  end

  def validate_address_postcode
    if address_postcode.present? && address_postcode.to_postcode.nil?
      errors.add(:address_postcode, "Enter a valid postcode, such as SW1A 1AA")
    end
  end
end
