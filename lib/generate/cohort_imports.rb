# frozen_string_literal: true

require "csv"

Faker::Config.locale = "en-GB"

# Use this to generate a cohort import CSV file for performance testing.
#
# Usage from the Rails console:
#
# Create a cohort import of 1000 children for all the school sessions for the
# org A9A5A in the local db:
#
#     Generate::CohortImports.call(patient_count: 1000)
#
# You can also generate a cohort import for sessions not in the local db.
#
#     Generate::CohortImports.call(
#       patient_count: 1000,
#       urns: ["123456", "987654"],
#       school_year_groups: {
#         "123456" => [-2, -1, 0, 1, 2, 3, 4, 5, 6],
#         "987654" => [9, 10, 11, 12, 13]
#       }
#     )
#
# You can pull out the year groups with the following:
#
#     org = Organisation.find_by(ods_code: "A9A5A")
#     org.locations.school.pluck(:urn, :year_groups) .to_h
#
module Generate
  class CohortImports
    attr_reader :ods_code,
                :organisation,
                :programme,
                :urns,
                :patient_count,
                :school_year_groups,
                :progress_bar

    def initialize(
      ods_code: "A9A5A",
      programme: "hpv",
      urns: nil,
      school_year_groups: nil,
      patient_count: 10,
      progress_bar: nil
    )
      @organisation = Organisation.find_by(ods_code:)
      @programme = Programme.find_by(type: programme)
      @urns =
        urns ||
          @organisation
            .locations
            .select { it.urn.present? }
            .sample(3)
            .pluck(:urn)
      @school_year_groups = school_year_groups
      @patient_count = patient_count
      @progress_bar = progress_bar
      @nhs_numbers = Set.new
    end

    def self.call(...) = new(...).call

    def call
      write_cohort_import_csv
    end

    def patients
      patient_count.times.lazy.map { build_patient }
    end

    private

    def cohort_import_csv_filepath
      Rails.root.join(
        "tmp/perf-test-cohort-import-#{organisation.ods_code}-#{programme.type}.csv"
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
          progress_bar&.increment
        end
      end
      cohort_import_csv_filepath.to_s
    end

    def programme_year_groups
      Programme::YEAR_GROUPS_BY_TYPE[programme.type]
    end

    def schools_with_year_groups
      @schools_with_year_groups ||=
        begin
          locations =
            if school_year_groups.present?
              urns.map do |urn|
                Location.new(urn:, year_groups: school_year_groups[urn])
              end
            else
              organisation
                .locations
                .where(urn: urns)
                .includes(:organisation, :sessions)
            end
          locations.select { (it.year_groups & programme_year_groups).any? }
        end
    end

    def build_patient
      school = schools_with_year_groups.sample
      year_group ||= (school.year_groups & programme_year_groups).sample
      nhs_number = nil
      loop do
        nhs_number = Faker::NationalHealthService.british_number.gsub(" ", "")
        break unless nhs_number.in? @nhs_numbers
      end
      @nhs_numbers << nhs_number

      FactoryBot
        .build(
          :patient,
          school:,
          organisation:,
          date_of_birth: date_of_birth_for_year(year_group),
          nhs_number:
        )
        .tap do |patient|
          patient.parents =
            FactoryBot.build_list(:parent, 2, family_name: patient.family_name)
          patient.parent_relationships =
            patient.parents.map do
              FactoryBot.build(:parent_relationship, parent: it, patient:)
            end
        end
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
end
