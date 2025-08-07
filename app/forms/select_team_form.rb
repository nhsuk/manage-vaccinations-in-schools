# frozen_string_literal: true

class SelectTeamForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :current_user, :request_session

  attribute :team_id, :integer

  validates :team_id, inclusion: { in: :team_id_values }

  def save
    return false if invalid?

    request_session["cis2_info"] = {
      "selected_org" => {
        "name" => team.name,
        "code" => organisation.ods_code
      },
      "selected_role" => {
        "code" => User::CIS2_NURSE_ROLE,
        "workgroups" => [User::CIS2_WORKGROUP]
      }
    }

    true
  end

  private

  def team = current_user.teams.includes(:organisation).find(team_id)

  delegate :organisation, to: :team

  def team_id_values = current_user.teams.pluck(:id)
end
