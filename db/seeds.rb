# frozen_string_literal: true

if Settings.disallow_database_seeding
  Rails.logger.info "Database seeding is disabled"
  exit
end

Faker::Config.locale = "en-GB"

def set_feature_flags
  FeatureFlagFactory.call
end

def seed_vaccines
  Rake::Task["vaccines:seed"].execute
end

def create_gp_practices
  FactoryBot.create_list(:gp_practice, 30)
end

def create_team(ods_code:, workgroup: nil, type: :poc_only)
  workgroup ||= ods_code.downcase

  Team.find_by(workgroup:) ||
    FactoryBot.create(
      :team,
      :with_generic_clinic,
      ods_code:,
      programmes: Programme.all,
      workgroup:,
      type:
    )
end

def create_user(role, team:, email: nil, uid: nil)
  if uid
    User.find_by(uid:) ||
      FactoryBot.create(
        role,
        uid:,
        family_name: "Flo",
        given_name: "Nurse",
        email: "nurse.flo@example.nhs.uk",
        provider: "cis2",
        team:
        # password: Do not set this as they should not log in via password
      )
  elsif email
    User.find_by(email:) ||
      FactoryBot.create(
        role,
        family_name: email.split("@").first.split(".").last.capitalize,
        given_name: email.split("@").first.split(".").first.capitalize,
        email:,
        password: email,
        team:
      )
  else
    raise "No email or UID provided"
  end
end

def attach_sample_of_schools_to(team)
  Location
    .school
    .where(subteam_id: nil)
    .order("RANDOM()")
    .limit(50)
    .update_all_and_sync_patient_teams(subteam_id: team.subteams.first.id)
end

def attach_specific_school_to_team_if_present(team:, urn:)
  Location.where(urn:).update_all_and_sync_patient_teams(
    subteam_id: team.subteams.first.id
  )
end

def create_session(user, team, programmes:, completed: false, year_groups: nil)
  year_groups ||= programmes.flat_map(&:default_year_groups).uniq

  Vaccine
    .active
    .where(programme: programmes)
    .find_each { |vaccine| FactoryBot.create(:batch, team:, vaccine:) }

  location = FactoryBot.create(:school, team:, gias_year_groups: year_groups)
  date = completed ? 1.week.ago.to_date : Date.current

  session = FactoryBot.create(:session, date:, team:, programmes:, location:)

  [date - 1.day, date + 1.day].each do |value|
    if value.in?(session.academic_year.to_academic_year_date_range)
      session.session_dates.create!(value:)
    end
  end

  programmes.each do |programme|
    year_groups.each do |year_group|
      patients_without_consent =
        FactoryBot.create_list(
          :patient,
          2,
          programmes: [programme],
          session:,
          performed_by: user,
          year_group:
        )

      patients_without_consent.each do |patient|
        FactoryBot.create(
          :consent_form,
          :recorded,
          given_name: patient.given_name,
          family_name: patient.family_name,
          session:
        )
      end

      # Add extra consent forms with a successful NHS number lookup
      temporary_patient = FactoryBot.build(:patient)
      FactoryBot.create(
        :consent_form,
        :recorded,
        given_name: temporary_patient.given_name,
        family_name: temporary_patient.family_name,
        nhs_number: temporary_patient.nhs_number,
        session:
      )

      traits = %i[
        consent_conflicting
        consent_given_triage_needed
        consent_given_triage_not_needed
        consent_refused
        consent_given_triage_delay_vaccination
        consent_given_triage_safe_to_vaccinate
        unable_to_vaccinate
        vaccinated
      ]

      traits << :partially_vaccinated_triage_needed if programme.td_ipv?

      traits.each do |trait|
        FactoryBot.create_list(
          :patient,
          1,
          trait,
          programmes: [programme],
          session:,
          performed_by: user,
          year_group:
        )
      end
    end
  end
end

def setup_clinic(team)
  academic_year = AcademicYear.current
  clinic_session = team.generic_clinic_session(academic_year:)

  [Date.current, Date.yesterday, Date.tomorrow].each do |value|
    if value.in?(academic_year.to_academic_year_date_range)
      clinic_session.session_dates.create!(value:)
    end
  end

  clinic_session.update!(send_invitations_at: Date.current - 3.weeks)

  # All unknown school or home-schooled patients belong to the community clinic.
  # This is normally handled by school moves, but here we need to do it manually.
  new_patient_location_records =
    team
      .patients
      .where(school: nil)
      .map do
        PatientLocation.new(
          patient: it,
          location: clinic_session.location,
          academic_year: clinic_session.academic_year
        )
      end

  imported_ids =
    PatientLocation.import(
      new_patient_location_records,
      on_duplicate_key_ignore: :all
    ).ids
  SyncPatientTeamJob.perform_now(PatientLocation, imported_ids)
end

def create_patients(team)
  team.schools.each do |school|
    FactoryBot.create_list(:patient, 4, team:, school:)
  end
end

def create_imports(user, team)
  %i[pending invalid processed].each do |status|
    FactoryBot.create(:cohort_import, status, team:, uploaded_by: user)
    FactoryBot.create(:immunisation_import, status, team:, uploaded_by: user)
    FactoryBot.create(
      :class_import,
      status,
      team:,
      session: team.sessions.includes(:location, :programmes).first,
      uploaded_by: user
    )
  end

  low_pds_import =
    FactoryBot.create(
      :cohort_import,
      :low_pds_match_rate,
      team:,
      uploaded_by: user
    )
  FactoryBot.create_list(
    :patient_changeset,
    15,
    import: low_pds_import,
    pds_nhs_number: nil
  )
end

def create_school_moves(team)
  patients = team.patients.sample(10)

  patients.each do |patient|
    if [true, false].sample
      FactoryBot.create(:school_move, :to_home_educated, patient:, team:)
    else
      FactoryBot.create(
        :school_move,
        :to_school,
        patient:,
        school: team.schools.sample
      )
    end
  end
end

def create_team_sessions(user, team)
  flu = Programme.find_by!(type: "flu")
  hpv = Programme.find_by!(type: "hpv")
  menacwy = Programme.find_by!(type: "menacwy")
  td_ipv = Programme.find_by!(type: "td_ipv")

  # Flu-only sessions
  create_session(user, team, programmes: [flu], completed: false)
  create_session(user, team, programmes: [hpv], completed: true)

  # HPV-only sessions
  create_session(user, team, programmes: [hpv], completed: false)
  create_session(user, team, programmes: [hpv], completed: true)

  # MenACWY and Td/IPV combined sessions
  create_session(
    user,
    team,
    programmes: [menacwy, td_ipv],
    completed: false,
    year_groups: [8, 9, 10]
  )

  # All three vaccines combined
  create_session(
    user,
    team,
    programmes: [menacwy, td_ipv, hpv],
    completed: false,
    year_groups: [8, 9, 10]
  )
end

set_feature_flags

seed_vaccines
create_gp_practices

def create_nurse_joy_team
  team = create_team(ods_code: "R1L")
  user = create_user(:nurse, team:, email: "nurse.joy@example.com")
  create_user(:medical_secretary, team:, email: "admin.hope@example.com")
  create_user(:superuser, team:, email: "superuser@example.com")
  create_user(:healthcare_assistant, team:, email: "hca@example.com")
  create_user(:prescriber, team:, email: "prescriber@example.com")

  attach_sample_of_schools_to(team)

  # Bohunt School Wokingham - used by automated tests
  attach_specific_school_to_team_if_present(team:, urn: "142181")

  # Barn End Centre - used by automated tests
  attach_specific_school_to_team_if_present(team:, urn: "118239")

  Audited.audit_class.as_user(user) { create_team_sessions(user, team) }
  setup_clinic(team)
  create_patients(team)
  create_imports(user, team)
  create_school_moves(team)
end

def create_upload_only_team
  team = create_team(ods_code: "XX99", type: :upload_only)
  create_user(:medical_secretary, team:, email: "admin.sarah@example.com")
  create_user(:superuser, team:, email: "superuser.rob@example.com")

  attach_sample_of_schools_to(team)
end

unless Settings.cis2.enabled
  # Don't create Nurse Joy's team on a CIS2 env, because password authentication
  # is not available and password= fails to run.
  create_nurse_joy_team

  create_upload_only_team
end

# CIS2 team - the ODS code and user UID need to match the values in the CIS2 env
team = create_team(ods_code: "A9A5A")
user = create_user(:nurse, team:, uid: "555057896106")

support_team =
  create_team(
    ods_code: CIS2Info::SUPPORT_ORGANISATION,
    workgroup: CIS2Info::SUPPORT_WORKGROUP
  )
create_user(:support, team: support_team, email: "support@example.com")

attach_sample_of_schools_to(team)

Audited.audit_class.as_user(user) { create_team_sessions(user, team) }
setup_clinic(team)
create_patients(team)
create_imports(user, team)
create_school_moves(team)

Team.find_each do |team|
  TeamSessionsFactory.call(
    team,
    academic_year: AcademicYear.current,
    sync_patient_teams_now: true
  )
end

Rake::Task["status:update:all"].execute
Rake::Task["smoke:seed"].execute
