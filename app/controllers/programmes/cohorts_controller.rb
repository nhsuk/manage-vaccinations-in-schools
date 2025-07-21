# frozen_string_literal: true

class Programmes::CohortsController < Programmes::BaseController
  include Pagy::Backend

  def index
    birth_academic_years =
      policy_scope(Location::ProgrammeYearGroup)
        .where(programme: @programme)
        .pluck_year_groups
        .map { it.to_birth_academic_year(academic_year: @academic_year) }

    @patient_count_by_birth_academic_year =
      patients_in_organisation
        .where(birth_academic_year: birth_academic_years)
        .group(:birth_academic_year)
        .count
        .then do |counts|
          birth_academic_years.index_with { |year| counts[year] || 0 }
        end
  end

  def show
    @birth_academic_year = Integer(params[:id])

    patients =
      patients_in_organisation
        .where(birth_academic_year: @birth_academic_year)
        .not_deceased
        .eager_load(:school)
        .order_by_name

    @pagy, @patients = pagy(patients)
  end

  private

  def patients_in_organisation
    current_user.selected_organisation.patients
  end
end
