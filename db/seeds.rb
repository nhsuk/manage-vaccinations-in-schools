# frozen_string_literal: true

if Settings.disallow_database_seeding
  Rails.logger.info "Database seeding is disabled"
  exit
end

Faker::Config.locale = "en-GB"

def set_feature_flags
  %i[dev_tools mesh_jobs cis2].each do |feature_flag|
    Flipper.add(feature_flag) unless Flipper.exist?(feature_flag)
  end
end

def seed_vaccines
  Rake::Task["vaccines:seed"].execute
end

def import_schools
  if Settings.fast_reset
    FactoryBot.create_list(:location, 30, :primary)
    FactoryBot.create_list(:location, 30, :secondary)
  else
    Rake::Task["schools:import"].execute
  end
end

def create_organisation(ods_code:)
  organisation =
    Organisation.find_by(ods_code:) ||
      FactoryBot.create(:organisation, :with_generic_clinic, ods_code:)

  programme = Programme.find_by(type: "hpv")
  FactoryBot.create(:organisation_programme, organisation:, programme:)

  organisation
end

def create_user(organisation:, email: nil, uid: nil, fallback_role: :nurse)
  if uid
    User.find_by(uid:) ||
      FactoryBot.create(
        :user,
        uid:,
        family_name: "Flo",
        given_name: "Nurse",
        email: "nurse.flo@example.nhs.uk",
        provider: "cis2",
        organisations: [organisation],
        fallback_role:
        # password: Do not set this as they should not log in via password
      )
  elsif email
    User.find_by(email:) ||
      FactoryBot.create(
        :user,
        family_name: email.split("@").first.split(".").last.capitalize,
        given_name: email.split("@").first.split(".").first.capitalize,
        email:,
        password: email,
        organisations: [organisation],
        fallback_role:
      )
  else
    raise "No email or UID provided"
  end
end

def attach_sample_of_schools_to(organisation)
  Location
    .school
    .order("RANDOM()")
    .limit(50)
    .update_all(team_id: organisation.generic_team.id)
end

def attach_specific_school_to_organisation_if_present(organisation:, urn:)
  Location.where(urn:).update_all(team_id: organisation.generic_team.id)
end

def get_location_for_session(organisation, programme)
  loop do
    location =
      organisation.locations.for_year_groups(programme.year_groups).sample ||
        FactoryBot.create(
          :location,
          :school,
          organisation:,
          year_groups: programme.year_groups
        )

    return location unless organisation.sessions.exists?(location:)
  end
end

def create_session(user, organisation, completed:)
  programme = Programme.find_by(type: "hpv")

  FactoryBot.create_list(
    :batch,
    4,
    organisation:,
    vaccine: programme.vaccines.active.first
  )

  location = get_location_for_session(organisation, programme)

  date = completed ? 1.week.ago.to_date : Date.current

  session =
    FactoryBot.create(:session, date:, organisation:, programme:, location:)

  session.session_dates.create!(value: date - 1.day)
  session.session_dates.create!(value: date + 1.day)

  patients_without_consent =
    FactoryBot.create_list(:patient_session, 4, programme:, session:, user:)
  unmatched_patients = patients_without_consent.sample(2).map(&:patient)
  unmatched_patients.each do |patient|
    FactoryBot.create(
      :consent_form,
      :recorded,
      programme:,
      given_name: patient.given_name,
      family_name: patient.family_name,
      session:
    )
  end

  %i[
    consent_given_triage_not_needed
    consent_given_triage_needed
    triaged_ready_to_vaccinate
    consent_refused
    consent_conflicting
    vaccinated
    delay_vaccination
    unable_to_vaccinate
  ].each do |trait|
    FactoryBot.create_list(
      :patient_session,
      3,
      trait,
      programme:,
      session:,
      user:
    )
  end
end

def create_patients(organisation)
  organisation.schools.each do |school|
    FactoryBot.create_list(:patient, 5, organisation:, school:)
  end
end

def create_imports(user, organisation)
  programme = organisation.programmes.find_by(type: "hpv")

  %i[pending invalid recorded].each do |status|
    FactoryBot.create(
      :cohort_import,
      status,
      organisation:,
      programme:,
      uploaded_by: user
    )
    FactoryBot.create(
      :immunisation_import,
      status,
      organisation:,
      programme:,
      uploaded_by: user
    )
    FactoryBot.create(
      :class_import,
      status,
      organisation:,
      session: programme.sessions.first,
      uploaded_by: user
    )
  end
end

set_feature_flags

seed_vaccines
import_schools

unless Settings.cis2.enabled
  # Don't create Nurse Joy's team on a CIS2 env, because password authentication
  # is not available and password= fails to run.
  organisation = create_organisation(ods_code: "R1L")
  user = create_user(organisation:, email: "nurse.joy@example.com")
  create_user(
    organisation:,
    email: "admin.hope@example.com",
    fallback_role: "admin"
  )

  attach_sample_of_schools_to(organisation)

  # Sidney Stringer Academy - used by automated tests
  attach_specific_school_to_organisation_if_present(
    organisation:,
    urn: "136126"
  )

  # Grange School - used by automated tests
  attach_specific_school_to_organisation_if_present(
    organisation:,
    urn: "145377"
  ) # needed for automated testing

  Audited
    .audit_class
    .as_user(user) do
      create_session(user, organisation, completed: false)
      create_session(user, organisation, completed: true)
    end
  create_patients(organisation)
  create_imports(user, organisation)
end

# CIS2 organisation - the ODS code and user UID need to match the values in the CIS2 env
organisation = create_organisation(ods_code: "A9A5A")
user = create_user(organisation:, uid: "555057896106")

attach_sample_of_schools_to(organisation)

# Sidney Stringer Academy - used by automated tests
attach_specific_school_to_organisation_if_present(organisation:, urn: "136126")

# Grange School - used by automated tests
attach_specific_school_to_organisation_if_present(organisation:, urn: "145377")

Audited
  .audit_class
  .as_user(user) do
    create_session(user, organisation, completed: false)
    create_session(user, organisation, completed: true)
  end
create_patients(organisation)
create_imports(user, organisation)

UnscheduledSessionsFactory.new.call
