# frozen_string_literal: true

class SelectOrganisationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :current_user, :request_session

  attribute :organisation_id, :integer

  validates :organisation_id, inclusion: { in: :organisation_id_values }

  def save
    return false if invalid?

    request_session["cis2_info"] = {
      "selected_org" => {
        "name" => organisation.name,
        "code" => organisation.ods_code
      },
      "selected_role" => {
        "code" => User::CIS2_NURSE_ROLE,
        "workgroups" => ["schoolagedimmunisations"]
      }
    }

    true
  end

  private

  def organisation = current_user.organisations.find(organisation_id)

  def organisation_id_values = current_user.organisations.pluck(:id)
end
