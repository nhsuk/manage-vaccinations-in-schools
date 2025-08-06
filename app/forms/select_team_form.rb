# frozen_string_literal: true

class SelectTeamForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :cis2_info, :current_user

  attribute :team_id, :integer

  validates :team_id, inclusion: { in: :team_id_values }

  def save
    return false if invalid?

    cis2_info.update!(
      organisation_name: team.name,
      organisation_code: organisation.ods_code,
      role_code: CIS2Info::NURSE_ROLE,
      workgroups: [CIS2Info::WORKGROUP]
    )

    true
  end

  private

  def team = current_user.teams.includes(:organisation).find(team_id)

  delegate :organisation, to: :team

  def team_id_values = current_user.teams.pluck(:id)
end
