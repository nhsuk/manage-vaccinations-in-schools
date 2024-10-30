# frozen_string_literal: true

class ClassImportRow < PatientImportRow
  def initialize(data:, session:)
    super(
      data:,
      organisation: session.organisation,
      year_groups: session.year_groups
    )
    @school = session.location
  end

  private

  attr_reader :school

  def home_educated
    false
  end
end
