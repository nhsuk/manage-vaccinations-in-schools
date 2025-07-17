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

def create_organisation(ods_code:)
  Organisation.find_by(ods_code:) ||
    FactoryBot.create(
      :organisation,
      :with_generic_clinic,
      ods_code:,
      programmes: Programme.all
    )
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
        organisation:,
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
        organisation:,
        fallback_role:
      )
  else
    raise "No email or UID provided"
  end
end

def attach_sample_of_schools_to(organisation)
  Location
    .school
    .where(team_id: nil)
    .order("RANDOM()")
    .limit(50)
    .update_all(team_id: organisation.generic_team.id)
end

def attach_specific_school_to_organisation_if_present(organisation:, urn:)
  Location.where(urn:).update_all(team_id: organisation.generic_team.id)
end

def create_session(
  user,
  organisation,
  programmes:,
  completed: false,
  year_groups: nil
)
  year_groups ||= programmes.flat_map(&:default_year_groups).uniq

  Vaccine
    .active
    .where(programme: programmes)
    .find_each { |vaccine| FactoryBot.create(:batch, organisation:, vaccine:) }

  location = FactoryBot.create(:school, organisation:, year_groups:)
  date = completed ? 1.week.ago.to_date : Date.current

  session =
    FactoryBot.create(:session, date:, organisation:, programmes:, location:)

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

def setup_clinic(organisation)
  clinic_session = organisation.generic_clinic_session

  clinic_session.session_dates.create!(value: Date.current)
  clinic_session.session_dates.create!(value: Date.current - 1.day)
  clinic_session.session_dates.create!(value: Date.current + 1.day)

  # All patients belong to the community clinic. This is normally
  # handled by school moves, but here we need to do it manually.

  PatientSession.import(
    organisation.patients.map do
      PatientSession.new(patient: it, session: clinic_session)
    end,
    on_duplicate_key_ignore: :all
  )
end

def create_patients(organisation)
  organisation.schools.each do |school|
    FactoryBot.create_list(:patient, 4, organisation:, school:)
  end
end

def create_imports(user, organisation)
  %i[pending invalid processed].each do |status|
    FactoryBot.create(:cohort_import, status, organisation:, uploaded_by: user)
    FactoryBot.create(
      :immunisation_import,
      status,
      organisation:,
      uploaded_by: user
    )
    FactoryBot.create(
      :class_import,
      status,
      organisation:,
      session: organisation.sessions.includes(:programmes).first,
      uploaded_by: user
    )
  end
end

def create_school_moves(organisation)
  patients = organisation.patients.sample(10)

  patients.each do |patient|
    if [true, false].sample
      FactoryBot.create(
        :school_move,
        :to_home_educated,
        patient:,
        organisation:
      )
    else
      FactoryBot.create(
        :school_move,
        :to_school,
        patient:,
        school: organisation.schools.sample
      )
    end
  end
end

def create_organisation_sessions(user, organisation)
  flu = Programme.find_by!(type: "flu")
  hpv = Programme.find_by!(type: "hpv")
  menacwy = Programme.find_by!(type: "menacwy")
  td_ipv = Programme.find_by!(type: "td_ipv")

  # Flu-only sessions
  create_session(user, organisation, programmes: [flu], completed: false)
  create_session(user, organisation, programmes: [hpv], completed: true)

  # HPV-only sessions
  create_session(user, organisation, programmes: [hpv], completed: false)
  create_session(user, organisation, programmes: [hpv], completed: true)

  # MenACWY and Td/IPV combined sessions
  create_session(
    user,
    organisation,
    programmes: [menacwy, td_ipv],
    completed: false,
    year_groups: [8, 9, 10]
  )

  # All three vaccines combined
  create_session(
    user,
    organisation,
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
  organisation = create_organisation(ods_code: "R1L")
  user = create_user(organisation:, email: "nurse.joy@example.com")
  create_user(
    organisation:,
    email: "admin.hope@example.com",
    fallback_role: "admin"
  )
  create_user(
    organisation:,
    email: "superuser@example.com",
    fallback_role: "superuser"
  )

  attach_sample_of_schools_to(organisation)

  # Bohunt School Wokingham - used by automated tests
  attach_specific_school_to_organisation_if_present(
    organisation:,
    urn: "142181"
  )

  # Barn End Centre - used by automated tests
  attach_specific_school_to_organisation_if_present(
    organisation:,
    urn: "118239"
  )

  Audited
    .audit_class
    .as_user(user) { create_organisation_sessions(user, organisation) }
  setup_clinic(organisation)
  create_patients(organisation)
  create_imports(user, organisation)
  create_school_moves(organisation)
end

# CIS2 organisation - the ODS code and user UID need to match the values in the CIS2 env
organisation = create_organisation(ods_code: "A9A5A")
user = create_user(organisation:, uid: "555057896106")

attach_sample_of_schools_to(organisation)

Audited
  .audit_class
  .as_user(user) { create_organisation_sessions(user, organisation) }
setup_clinic(organisation)
create_patients(organisation)
create_imports(user, organisation)
create_school_moves(organisation)

UnscheduledSessionsFactory.new.call

Rake::Task["status:update:all"].execute
Rake::Task["gp_practices:smoke"].execute
Rake::Task["schools:smoke"].execute
