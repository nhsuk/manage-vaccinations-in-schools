# frozen_string_literal: true

class Programmes::OverviewController < Programmes::BaseController
  before_action :set_consents
  before_action :set_patient_ids
  before_action :set_patient_count_by_year_group

  def show
  end

  private

  def set_consents
    @consents =
      policy_scope(Consent).where_programme(@programme).where(
        patient_id: patient_ids,
        academic_year: @academic_year
      )
  end

  def set_patient_ids
    @patient_ids = patient_ids
  end

  def set_patient_count_by_year_group
    year_groups =
      current_team.programme_year_groups(academic_year: @academic_year)[
        @programme
      ]

    patient_count_by_birth_academic_year =
      Patient.where(id: patient_ids).group(:birth_academic_year).count

    @patient_count_by_year_group =
      year_groups.index_with do |year_group|
        birth_academic_year =
          year_group.to_birth_academic_year(academic_year: @academic_year)
        patient_count_by_birth_academic_year[birth_academic_year] || 0
      end
  end
end
