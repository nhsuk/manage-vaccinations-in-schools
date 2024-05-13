class PilotController < ApplicationController
  skip_after_action :verify_policy_scoped, only: %i[manage]

  layout "two_thirds", except: %i[registrations]

  def manage
  end

  def registrations
    @schools = policy_scope(Location).includes(:registrations)
  end

  def download
    registrations = policy_scope(Registration)
    csv = CohortList.from_registrations(registrations).to_csv
    send_data(csv, filename: "registered_parents.csv")
  end
end
