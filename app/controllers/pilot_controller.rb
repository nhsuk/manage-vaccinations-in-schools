class PilotController < ApplicationController
  layout "two_thirds", except: %i[registrations]

  def manage
  end

  def manual
  end

  def registrations
    @registrations =
      Registration.where(
        location_id: current_user.team.locations.map(&:id)
      ).group_by(&:location)
  end

  def download
    registrations = Registration.where(location: current_user.team.locations)
    csv = CohortList.from_registrations(registrations).to_csv
    send_data(csv, filename: "registered_parents.csv")
  end
end
