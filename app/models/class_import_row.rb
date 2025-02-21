# frozen_string_literal: true

class ClassImportRow < PatientImportRow
  validates :address_postcode, postcode: { allow_nil: true }

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
end
