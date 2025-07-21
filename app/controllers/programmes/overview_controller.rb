# frozen_string_literal: true

class Programmes::OverviewController < Programmes::BaseController
  before_action :set_consents
  before_action :set_patient_count_by_year_group

  def show
  end

  private

  def set_consents
    @consents =
      policy_scope(Consent).where(
        patient: patients,
        programme: @programme,
        submitted_at: @academic_year.to_academic_year_date_range
      )
  end

  def set_patient_count_by_year_group
    year_groups =
      policy_scope(Location::ProgrammeYearGroup).where(
        programme: @programme
      ).pluck_year_groups

    patient_count_by_birth_academic_year =
      patients.group(:birth_academic_year).count

    @patient_count_by_year_group =
      year_groups.index_with do |year_group|
        birth_academic_year =
          year_group.to_birth_academic_year(academic_year: @academic_year)
        patient_count_by_birth_academic_year[birth_academic_year] || 0
      end
  end

  def patients
    @patients ||=
      policy_scope(Patient).appear_in_programmes(
        [@programme],
        academic_year: @academic_year
      )
  end
end
