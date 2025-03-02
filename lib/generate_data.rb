#!/usr/bin/env ruby

## Table name: patients
#
#  id                        :bigint           not null, primary key
#  address_line_1            :string
#  address_line_2            :string
#  address_postcode          :string
#  address_town              :string
#  birth_academic_year       :integer          not null
#  date_of_birth             :date             not null
#  date_of_death             :date
#  date_of_death_recorded_at :datetime
#  family_name               :string           not null
#  gender_code               :integer          default("not_known"), not null
#  given_name                :string           not null
#  home_educated             :boolean
#  invalidated_at            :datetime
#  nhs_number                :string
#  pending_changes           :jsonb            not null
#  preferred_family_name     :string
#  preferred_given_name      :string
#  registration              :string
#  restricted_at             :datetime
#  updated_from_pds_at       :datetime
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  gp_practice_id            :bigint
#  organisation_id           :bigint
#  school_id                 :bigint

require "csv"

Faker::Config.locale = "en-GB"

class GenerateData
  attr_reader :ods_code,
              :organisation,
              :programme,
              :urns,
              :patient_count,
              :patients

  def initialize(
    ods_code: "A9A5A",
    programme: "hpv",
    urns: nil,
    patient_count: 10
  )
    @organisation = Organisation.find_by(ods_code:)
    @programme = Programme.find_by(type: programme)
    @urns =
      urns ||
        @organisation.locations.select { it.urn.present? }.sample(3).pluck(:urn)
    @patient_count = patient_count
    @patients = nil
  end

  def generate
    @patients ||= build_patients
  end

  def generate_csv
    generate
    write_cohort_import_csv
    write_class_import_csv
  end

  def cohort_import_csv_filepath
    Rails.root.join(
      "tmp/perf-test-cohort-import-#{organisation.ods_code}-#{programme.type}.csv"
    )
  end

  def class_import_csv_filepath(school:)
    Rails.root.join(
      "tmp/perf-test-class-import-#{school.name}-#{school.sessions.first.slug}.csv"
    )
  end

  def write_cohort_import_csv
    CSV.open(cohort_import_csv_filepath, "w") do |csv|
      csv << %w[
        CHILD_ADDRESS_LINE_1
        CHILD_ADDRESS_LINE_2
        CHILD_POSTCODE
        CHILD_TOWN
        CHILD_PREFERRED_GIVEN_NAME
        CHILD_DATE_OF_BIRTH
        CHILD_FIRST_NAME
        CHILD_LAST_NAME
        CHILD_NHS_NUMBER
        PARENT_1_EMAIL
        PARENT_1_NAME
        PARENT_1_PHONE
        PARENT_1_RELATIONSHIP
        PARENT_2_EMAIL
        PARENT_2_NAME
        PARENT_2_PHONE
        PARENT_2_RELATIONSHIP
        CHILD_SCHOOL_URN
      ]

      patients.each do |patient|
        csv << [
          patient.address_line_1,
          patient.address_line_2,
          patient.address_postcode,
          patient.address_town,
          patient.preferred_given_name,
          patient.date_of_birth,
          patient.given_name,
          patient.family_name,
          patient.nhs_number,
          patient.parents.first&.email,
          patient.parents.first&.full_name,
          patient.parents.first&.phone,
          patient.parent_relationships.first&.type,
          patient.parents.second&.email,
          patient.parents.second&.full_name,
          patient.parents.second&.phone,
          patient.parent_relationships.second&.type,
          patient.school.urn
        ]
      end
    end
  end

  def write_class_import_csv
    patients
      .group_by(&:school)
      .each do |school, school_patients|
        next if school.nil?

        CSV.open(class_import_csv_filepath(school:), "w") do |csv|
          csv << %w[
            CHILD_POSTCODE
            CHILD_DATE_OF_BIRTH
            CHILD_FIRST_NAME
            CHILD_LAST_NAME
            PARENT_1_EMAIL
            PARENT_1_PHONE
            PARENT_2_EMAIL
            PARENT_2_PHONE
          ]

          school_patients.each do |patient|
            csv << [
              patient.address_postcode,
              patient.date_of_birth,
              patient.given_name,
              patient.family_name,
              patient.parents.first&.email,
              patient.parents.first&.phone,
              patient.parents.second&.email,
              patient.parents.second&.phone
            ]
          end
        end
      end
  end

  def programme_year_groups
    Programme::YEAR_GROUPS_BY_TYPE[programme.type]
  end

  def schools_with_year_groups
    @schools_with_year_groups ||=
      organisation
        .locations
        .includes(:organisation, :sessions)
        .select { (it.year_groups & programme_year_groups).any? }
  end

  def build_patient(year_group: nil)
    school = schools_with_year_groups.sample
    year_group ||= (school.year_groups & programme_year_groups).sample

    FactoryBot
      .build(
        :patient,
        school:,
        date_of_birth: date_of_birth_for_year(year_group),
        nhs_number_base: 999_900_000
      )
      .tap do |patient|
        patient.parents =
          FactoryBot.build_list(:parent, 2, family_name: patient.family_name)
        patient.parent_relationships =
          patient.parents.map do
            FactoryBot.build(:parent_relationship, parent: it)
          end
      end
  end

  def build_patients()
    @patients = patient_count.times.map { build_patient() }
  end

  def date_of_birth_for_year(
    year_group,
    academic_year: Date.current.academic_year
  )
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
end
