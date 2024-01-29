class PilotController < ApplicationController
  layout "two_thirds", except: %i[registrations]

  def manage
  end

  def manual
  end

  def registrations
    @schools = current_user.team.locations.includes(:registrations)
  end

  def download
    registrations = Registration.where(location: current_user.team.locations)
    csv = CohortList.from_registrations(registrations).to_csv
    send_data(csv, filename: "registered_parents.csv")
  end
end
