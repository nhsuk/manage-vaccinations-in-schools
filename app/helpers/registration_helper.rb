module RegistrationHelper
  def school_registrations(school)
    Registration.where(location_id: school.id)
  end
end
