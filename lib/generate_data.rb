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
              :student_count,
              :students

  def initialize(
    ods_code: "A9A5A",
    programme: "hpv",
    urns: nil,
    student_count: 10
  )
    @organisation = Organisation.find_by(ods_code:)
    @programme = Programme.find_by(type: programme)
    @urns =
      urns ||
        @organisation.locations.select { it.urn.present? }.sample(3).pluck(:urn)
    @student_count = student_count
    @students = nil
  end

  def generate
    @students ||= create_students
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

      students.each do |student|
        csv << [
          student.address_line_1,
          student.address_line_2,
          student.address_postcode,
          student.address_town,
          student.preferred_given_name,
          student.date_of_birth,
          student.given_name,
          student.family_name,
          student.nhs_number,
          student.parents.first&.email,
          student.parents.first&.full_name,
          student.parents.first&.phone,
          student.parent_relationships.first&.type,
          student.parents.second&.email,
          student.parents.second&.full_name,
          student.parents.second&.phone,
          student.parent_relationships.second&.type,
          student.school.urn
        ]
      end
    end
  end

  def write_class_import_csv
    students
      .group_by(&:school)
      .each do |school, school_students|
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

          school_students.each do |student|
            csv << [
              student.address_postcode,
              student.date_of_birth,
              student.given_name,
              student.family_name,
              student.parents.first&.email,
              student.parents.first&.phone,
              student.parents.second&.email,
              student.parents.second&.phone
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

  def build_student(year_group: nil)
    school = schools_with_year_groups.sample
    year_group ||= (school.year_groups & programme_year_groups).sample

    FactoryBot.build(
      :patient,
      school:,
      date_of_birth: date_of_birth_for_year(year_group),
      nhs_number_base: 999_900_000
    )
  end

  def build_students()
    @students = student_count.times.map { build_student() }
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
