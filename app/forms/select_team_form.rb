# frozen_string_literal: true

class SelectTeamForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :cis2_info, :current_user

  attribute :team_id, :integer

  validates :team_id, inclusion: { in: :team_id_values }

  def save
    return false if invalid?

    team = teams.find(team_id)

    cis2_info.update!(team_workgroup: team.workgroup)

    unless Settings.cis2.enabled
      cis2_info.update!(
        organisation_code: team.organisation.ods_code,
        role_code: CIS2Info::NURSE_ROLE,
        workgroups: [CIS2Info::WORKGROUP] + [team.workgroup]
      )
    end

    true
  end

  def teams
    if Settings.cis2.enabled
      cis2_info.organisation.teams.where(workgroup: cis2_info.workgroups)
    else
      current_user.teams
    end
  end

  private

  def team_id_values = teams.pluck(:id)
end
