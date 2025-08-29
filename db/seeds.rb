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

def create_team(ods_code:)
  workgroup = ods_code.downcase

  Team.find_by(workgroup:) ||
    FactoryBot.create(
      :team,
      :with_generic_clinic,
      ods_code:,
      programmes: Programme.all,
      workgroup:
    )
end

def create_user(team:, email: nil, uid: nil, fallback_role: :nurse)
  if uid
    User.find_by(uid:) ||
      FactoryBot.create(
        :user,
        uid:,
        family_name: "Flo",
        given_name: "Nurse",
        email: "nurse.flo@example.nhs.uk",
        provider: "cis2",
        team:,
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
        team:,
        fallback_role:
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
    .update_all(subteam_id: team.subteams.first.id)
end

def attach_specific_school_to_team_if_present(team:, urn:)
  Location.where(urn:).update_all(subteam_id: team.subteams.first.id)
end

def create_session(user, team, programmes:, completed: false, year_groups: nil)
  year_groups ||= programmes.flat_map(&:default_year_groups).uniq

  Vaccine
    .active
    .where(programme: programmes)
    .find_each { |vaccine| FactoryBot.create(:batch, team:, vaccine:) }

  location = FactoryBot.create(:school, team:, year_groups:)
  date = completed ? 1.week.ago.to_date : Date.current

  session = FactoryBot.create(:session, date:, team:, programmes:, location:)

  session.session_dates.create!(value: date - 1.day)
  session.session_dates.create!(value: date + 1.day)

  programmes.each do |programme|
    year_groups.each do |year_group|
      patients_without_consent =
        FactoryBot.create_list(
          :patient_session,
          2,
          programmes: [programme],
          session:,
          user:,
          year_group:
        )
      unmatched_patients = patients_without_consent.sample(2).map(&:patient)
      unmatched_patients.each do |patient|
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
        consent_given_triage_not_needed
        consent_given_triage_needed
        triaged_ready_to_vaccinate
        consent_refused
        consent_conflicting
        vaccinated
        delay_vaccination
        unable_to_vaccinate
      ]

      if programme.vaccinated_dose_sequence != 1
        traits << :partially_vaccinated_triage_needed
      end

      traits.each do |trait|
        FactoryBot.create_list(
          :patient_session,
          1,
          trait,
          programmes: [programme],
          session:,
          user:,
          year_group:
        )
      end
    end
  end
end

def setup_clinic(team)
  academic_year = AcademicYear.current
  clinic_session = team.generic_clinic_session(academic_year:)

  clinic_session.session_dates.create!(value: Date.current)
  clinic_session.session_dates.create!(value: Date.current - 1.day)
  clinic_session.session_dates.create!(value: Date.current + 1.day)
  clinic_session.update!(send_invitations_at: Date.current - 3.weeks)

  # All patients belong to the community clinic. This is normally
  # handled by school moves, but here we need to do it manually.

  PatientSession.import(
    team.patients.map do
      PatientSession.new(patient: it, session: clinic_session)
    end,
    on_duplicate_key_ignore: :all
  )
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

unless Settings.cis2.enabled
  # Don't create Nurse Joy's team on a CIS2 env, because password authentication
  # is not available and password= fails to run.
  team = create_team(ods_code: "R1L")
  user = create_user(team:, email: "nurse.joy@example.com")
  create_user(team:, email: "admin.hope@example.com", fallback_role: "admin")
  create_user(team:, email: "superuser@example.com", fallback_role: "superuser")
  create_user(
    team:,
    email: "hca@example.com",
    fallback_role: "healthcare_assistant"
  )

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

# CIS2 team - the ODS code and user UID need to match the values in the CIS2 env
team = create_team(ods_code: "A9A5A")
user = create_user(team:, uid: "555057896106")

attach_sample_of_schools_to(team)

Audited.audit_class.as_user(user) { create_team_sessions(user, team) }
setup_clinic(team)
create_patients(team)
create_imports(user, team)
create_school_moves(team)

Team.find_each do |team|
  TeamSessionsFactory.call(team, academic_year: AcademicYear.current)
end

Rake::Task["status:update:all"].execute
Rake::Task["smoke:seed"].execute
