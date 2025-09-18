# frozen_string_literal: true

class ProgrammeBirthAcademicYears
  def initialize(programme_year_groups, academic_year:)
    @programme_year_groups = programme_year_groups
    @academic_year = academic_year
  end

  def [](programme)
    programme_year_groups[programme].map do
      it.to_birth_academic_year(academic_year:)
    end
  end

  private

  attr_reader :programme_year_groups, :academic_year
end
