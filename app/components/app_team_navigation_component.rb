# frozen_string_literal: true

class AppTeamNavigationComponent < ViewComponent::Base
  def initialize(team:)
    @team = team
  end

  def call
    render AppSubNavigationComponent.new do |nav|
      nav.with_item(
        href: contact_details_team_path,
        text: "Contact details",
        selected: request.path.ends_with?("contact_details")
      )
      nav.with_item(
        href: clinics_team_path,
        text: "Clinics",
        selected: request.path.ends_with?("clinics")
      )
      nav.with_item(
        href: schools_team_path,
        text: "Schools",
        selected: request.path.ends_with?("schools")
      )
      nav.with_item(
        href: sessions_team_path,
        text: "Sessions",
        selected: request.path.ends_with?("sessions")
      )
    end
  end
end
