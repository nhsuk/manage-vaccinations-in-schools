# Ops tasks

## Remove patients from sessions

If it's necessary to bulk remove patients from sessions (i.e. more than a few usages of "Remove from cohort" required), the following commands can be used in a Rails console:

```rb
org = Organisation.find_by(ods_code: "")
location = org.schools.find_by(name: "School name")
session = org.sessions.find_by(location:)

session.patients.count # get the number of patients

# check all the patients can be safely removed from the session
session.patient_sessions.all?(&:safe_to_destroy?)

# update all the patients to unknown school
session.patients.update_all(
  cohort_id: nil,
  home_educated: false,
  school_id: nil
)

# removes all patients from the session
session.patient_sessions.destroy_all
```

## Move patient from community clinic to session

We've had patients who have somehow ended up in a community clinic instead of a session, even though they are associated with the correct school. This command will assign them to the session at their school:

```rb
patient = Patient.find(...)

SchoolMove.new(patient:, school: patient.school).confirm!(move_to_school: true)
```

## Add a location to an organisation and add patients to the session

Normally patients are added to a location on import. However, their may be cases when they need to be added to a location after they've been imported, for example if their school was not added to the organisation at the time the patients were imported. At the time of writing, re-importing the patients does not add them to the location's session or to the organisation's cohorts.

To fix this, ensure the location has been added to the school using the [`schools:add_to_organisation` Rake task](rake-tasks.md#schoolsadd_to_organisationods_codeteam_nameurn).

The following console commands will manually add an existing patient to the location's session and the organisation's cohorts by using the logic in `SchoolMove`.

```rb
# Find the location
loc = Location.find_by(urn: "...")

# The location should only have one session with no patients:
loc.sessions.first.patients.count
=> 0

# Use the logic in SchoolMove to associate each patient with the location session
loc.patients.each { SchoolMove.new(patient: _1, school: loc).confirm! }

# Confirm that the patients have been added
loc.sessions.first.patients.count
=> 294
```

## Get Gillick patients who don't want their parents notified

```rb
Consent.where(notify_parents: false).pluck(:patient_id)
```

## Consent response stats per school

```rb
organisation = Organisation.find_by(ods_code: "...")

dates = {}
sessions = organisation.sessions

sessions
  .eager_load(:location)
  .each do |session|
    Consent
      .where(organisation:, patient: session.patients)
      .each do |consent|
        dates[consent.responded_at.to_date] ||= {}
        dates[consent.responded_at.to_date][session.location] ||= 0
        dates[consent.responded_at.to_date][session.location] += 1
      end
  end

str =
  CSV.generate do |csv|
    csv << [""] + sessions.map { _1.location.name }
    csv << ["Cohort"] + sessions.map { _1.patients.count }

    dates.keys.sort.each do |date|
      csv << [date.iso8601] + sessions.map { dates[date].fetch(_1.location, 0) }
    end
  end

puts str
```

## Taking the service offline

To quickly take the service offline (for client users) there is a `basic_auth` feature flag which can be added and enabled. In production the credentials for this are secret and therefore this acts as a quick way of preventing users from accessing the service.

### From the UI

1. Visit https://manage-vaccinations-in-schools.nhs.uk/flipper
2. Add the `basic_auth` feature flag if it doesn't exist already
3. Enable the `basic_auth` feature flag

### From a Rails console

```ruby
Flipper.enable(:basic_auth)
```

## Removing parent from a patient

```rb
patient = Patient.find(_)

# Find the parent you need to remove from the patient.
patient.parents.pluck(:id, :full_name, :email, :phone)
parent = patient.parents.find(_)

# Remove the parent relationship
patient.parent_relationships.find_by(parent:).destroy

# Check that the parent has other patients or any consents linked to them
parent.patients
parent.consents

# If the parent doesn't have any more patients or consents they can removed.
# Check with the original request to see if this is appropriate.
parent.destroy
```

## Move a patient from a school session to a community clinic

This can be done manually, and doesn't need a `SchoolMove`:

```rb
# Check if the patient session in question is safe to be destroyed.
patient.patient_sessions.first.safe_to_destroy?

patient.patient_sessions.first.destroy

patient.sessions << clinic_session
```
