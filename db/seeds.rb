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
    FactoryBot.create_list(:location, 30, :school)
  else
    Rake::Task["schools:import"].execute
  end
end

def create_team(ods_code:)
  team = Team.find_by(ods_code:) || FactoryBot.create(:team, ods_code:)

  programme = Programme.find_by(type: "hpv")
  FactoryBot.create(:team_programme, team:, programme:)

  team
end

def create_user_and_team(ods_code:, uid: nil)
  team = create_team(ods_code:)
  user =
    if uid
      User.find_by(uid:) ||
        FactoryBot.create(
          :user,
          uid:,
          family_name: "Flo",
          given_name: "Nurse",
          email: "nurse.flo@example.nhs.uk",
          provider: "cis2",
          teams: [team]
          # password: Do not set this as they should not log in via password
        )
    else
      User.find_by(email: "nurse.joy@example.com") ||
        FactoryBot.create(
          :user,
          family_name: "Joy",
          given_name: "Nurse",
          email: "nurse.joy@example.com",
          password: "nurse.joy@example.com",
          teams: [team]
        )
    end

  [user, team]
end

def attach_locations_to(team)
  Location.order("RANDOM()").limit(50).update_all(team_id: team.id)
end

def create_session(_user, team)
  programme = Programme.find_by(type: "hpv")

  FactoryBot.create_list(:batch, 4, vaccine: programme.vaccines.active.first)

  location =
    team.locations.for_year_groups(programme.year_groups).sample ||
      FactoryBot.create(
        :location,
        :school,
        team:,
        year_groups: programme.year_groups
      )

  session = FactoryBot.create(:session, team:, programme:, location:)

  session.dates.create!(value: Date.yesterday)
  session.dates.create!(value: Date.tomorrow)

  patients_without_consent =
    FactoryBot.create_list(:patient_session, 4, programme:, session:)
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
    FactoryBot.create_list(:patient_session, 3, trait, programme:, session:)
  end

  UnscheduledSessionsFactory.new.call
end

def create_patients(team)
  team.schools.each do |school|
    FactoryBot.create_list(:patient, 5, team:, school:)
  end
end

def create_imports(team)
  programme = team.programmes.find_by(type: "hpv")

  %i[pending invalid recorded].each do |status|
    FactoryBot.create(:cohort_import, status, team:, programme:)
    FactoryBot.create(:immunisation_import, status, team:, programme:)
    FactoryBot.create(
      :class_import,
      status,
      team:,
      session: programme.sessions.first
    )
  end
end

set_feature_flags

seed_vaccines
import_schools

# Nurse Joy's team
user, team = create_user_and_team(ods_code: "R1L")

attach_locations_to(team)
Audited.audit_class.as_user(user) { create_session(user, team) }
create_patients(team)
create_imports(team)

# CIS2 team - the ODS code and user UID need to match the values in the CIS2 env
user, team = create_user_and_team(ods_code: "Y51", uid: "555057896106")

attach_locations_to(team)
Audited.audit_class.as_user(user) { create_session(user, team) }
create_patients(team)
create_imports(team)
