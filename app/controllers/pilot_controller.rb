class PilotController < ApplicationController
  layout "two_thirds", except: %i[registrations]

  def manage
  end

  def manual
  end

  def registrations
    @registrations =
      Registration
        .where(location_id: current_user.team.locations.map(&:id))
        .group_by { |r| r.location.name }
  end
end
