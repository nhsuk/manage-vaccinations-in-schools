# frozen_string_literal: true

require_relative "../config/environment"
require "csv"

Faker::Config.locale = "en-GB"

# e.g. date_of_birth_for_year("2024", 8) => Mon, 09 Jan 2012
def date_of_birth_for_year(academic_year, year_group)
  academic_year = academic_year.to_s
  year_group = year_group.to_i

  if year_group < 12
    start_date = Date.new(academic_year.to_i - (year_group.to_i + 5), 9, 1)
    end_date = Date.new(academic_year.to_i - (year_group.to_i + 4), 8, 31)
    rand(start_date..end_date)
  else
    raise "Unknown year group: #{year_group}"
  end
end

def wrap_in_rollbackable_transaction
  ActiveRecord::Base.transaction do
    yield
    raise ActiveRecord::Rollback
  end
end

def create_student(school, year_group, team)
  FactoryBot
    .create(
      :patient,
      school:,
      date_of_birth: date_of_birth_for_year(2024, year_group),
      team:
    )
    .tap do |student|
      parents = FactoryBot.create_list(:parent, rand(1..2))
      parents.each do |parent|
        FactoryBot.create(:parent_relationship, parent:, patient: student)
      end
    end
end

def create_vaccination_record(
  student,
  vaccine:,
  session:,
  batch:,
  programme:,
  dose_sequence:
)
  print "+"
  FactoryBot.create(
    :vaccination_record,
    :performed_by_not_user,
    patient: student,
    session:,
    patient_session: PatientSession.find_by(patient: student, session:),
    programme:,
    vaccine:,
    administered_at: session.dates.first.value + rand(8..16).hours,
    batch:,
    dose_sequence:
  )
end

def write_nominal_roll_to_file(students)
  CSV.open("scratchpad/nominal_roll.csv", "w") do |csv|
    csv << CohortImport.new.send(:required_headers)

    students.each do |student|
      csv << [
        student.address_line_1,
        student.address_line_2,
        student.address_postcode,
        student.address_town,
        student.common_name,
        student.date_of_birth,
        student.first_name,
        student.last_name,
        student.nhs_number,
        student.parents.first&.email,
        student.parents.first&.name,
        student.parents.first&.phone,
        student.parent_relationships.first&.type,
        student.parents.second&.email,
        student.parents.second&.name,
        student.parents.second&.phone,
        student.parent_relationships.second&.type,
        student.school.urn
      ]
    end
  end
end

def write_vaccination_records_to_file(vaccination_records)
  CSV.open("scratchpad/vaccination_records.csv", "w") do |csv|
    csv << ImmunisationImport
      .new
      .send(:required_headers)
      .append("DOSE_SEQUENCE", "PERSON_GENDER_CODE", "CARE_SETTING")

    vaccination_records.each do |vaccination_record|
      csv << [
        vaccination_record.team.ods_code,
        vaccination_record.patient.school.urn,
        nil, # school name
        vaccination_record.patient.nhs_number,
        vaccination_record.patient.first_name,
        vaccination_record.patient.last_name,
        vaccination_record.patient.date_of_birth.to_fs(:dps),
        vaccination_record.patient.address_postcode,
        vaccination_record.administered_at.to_date.to_fs(:dps),
        vaccination_record.vaccine.brand.gsub(" ", ""),
        vaccination_record.batch.name,
        vaccination_record.batch.expiry.to_fs(:dps),
        ImmunisationImportRow::DELIVERY_SITES.key(
          vaccination_record.delivery_site
        ),
        vaccination_record.dose_sequence,
        vaccination_record.patient.gender_code.humanize,
        1 # CARE_SETTING
      ]
    end
  end
end

def create_students_and_vaccinations_for(school:, team:, year_size_estimate:)
  programme = Programme.find_by(type: "hpv")
  gardasil = Vaccine.find_by(brand: "Gardasil")
  gardasil9 = Vaccine.find_by(brand: "Gardasil 9")

  # define the cohort
  year_8s, year_9s, year_10s, year_11s =
    (8..11).map do |year_group|
      year_size_estimate.times.map { create_student(school, year_group, team) }
    end

  # define the vaccination history year by year
  # it's currently the 24/25 academic year
  # in 23/24 the year 9s got dose 1 of Gardasil9
  # in 22/23 the year 10s got dose 1 of Gardasil and the year 11s got dose 2 of Gardasil
  # in 21/22 the year 11s got dose 1 of Gardasil (the year 12s aged out of the cohort)

  who_got_what_when = [
    {
      session_date: Date.new(2024, 1, 1) + rand(1..90).days,
      vaccine: gardasil9,
      dose_1_cohort: year_9s
    },
    {
      session_date: Date.new(2023, 1, 1) + rand(1..90).days,
      vaccine: gardasil,
      dose_1_cohort: year_10s,
      dose_2_cohort: year_11s
    },
    {
      session_date: Date.new(2022, 1, 1) + rand(1..90).days,
      vaccine: gardasil,
      dose_1_cohort: year_11s
    }
  ]

  vaccination_records =
    who_got_what_when.flat_map do |row|
      session_date, vaccine, dose_1_cohort, dose_2_cohort =
        row.values_at(:session_date, :vaccine, :dose_1_cohort, :dose_2_cohort)

      session =
        FactoryBot.create(
          :session,
          programme:,
          date: session_date,
          team:,
          location: school
        )
      batch = FactoryBot.create(:batch, vaccine:)

      session_participants = [dose_1_cohort, dose_2_cohort].flatten.compact
      session.patients << session_participants

      session_participants.filter_map do |student|
        next if rand < 0.1 # assume 90% uptake
        dose_sequence = dose_1_cohort.include?(student) ? 1 : 2
        create_vaccination_record(
          student,
          vaccine:,
          session:,
          batch:,
          dose_sequence:,
          programme:
        )
      end
    end

  [year_8s + year_9s + year_10s + year_11s, vaccination_records]
end

# 1. SAIS team's admins will upload their entire year 8, 9, 10 and 11 nominal
# rolls into Mavis as one or more cohort uploads. Based on the date of birth
# of the child, Mavis will automatically sort the children into the correct
# HPV cohort. If they don't fit into any of the cohorts, then Mavis will
# raise an error and won't import them.

team = User.find_by(email: "nurse.ryg@example.com").team

school_data = CSV.read("scratchpad/school-class-sizes.csv", headers: true)

wrap_in_rollbackable_transaction do
  students = []
  vaccination_records = []

  school_data.flat_map do |row|
    school = Location.find_by(urn: row["urn"])

    s, v =
      create_students_and_vaccinations_for(
        school:,
        team:,
        year_size_estimate: row["year_estimate"].to_i
      )
    students += s
    vaccination_records += v
  end

  write_nominal_roll_to_file(students)
  write_vaccination_records_to_file(vaccination_records)
  print "."
end

#
# 2. The admin team will bulk-upload vaccination records of those children in
# year 9, 10 and 11 who have already been vaccinated in the previous years'
# programmes.
#
# 3. Using Mavis' one record per child model, Mavis will therefore know which
# children from each cohort are already vaccinated, and which are eligible
# for vaccination in this programme
#
# 4. When lead nurses receive the class lists for year 8, 9, 10 and 11 back
# from schools, they will upload these directly into Mavis as cohort records
# (separate uploads by school).
#
# 5. Mavis automatically matches the new records to those already in the
# system, and adds the new parent contact information to existing child
# records where it does not already exist. Where Mavis cannot reliably find
# an exact match to a child, the nurse will be prompted to find the correct
# match manually, or create a new record if the child is new to the area.
#
# 6. Records for any children who were previously thought to be in that
# school but weren't on the class list will be flagged to the nurse to be
# moved to the "unknown school" list.
#
# 7. Once the class lists are uploaded for a given school, the lead nurse can
# add a new school session, select the school and select that HPV will be the
# only vaccination type available. The nurse will then see a list of all
# eligible children from all active programs who have not yet had the HPV
# vaccination, to add them to the school session.
