# frozen_string_literal: true

module MavisCLI
  module VaccinationRecords
    class GenerateFHIR < Dry::CLI::Command
      desc "Generate FHIR record for a given vaccination record"
      argument :vaccination_record_id, desc: "The ID of the vaccination record"

      def call(vaccination_record_id:, **)
        MavisCLI.load_rails

        vaccination_record =
          ::VaccinationRecord.find_by(id: vaccination_record_id)

        if vaccination_record.nil?
          puts "Error: Vaccination record with ID #{vaccination_record_id} not found"
          return
        end

        if vaccination_record.not_administered?
          outcome = vaccination_record.outcome.humanize
          puts "Error: Vaccination record with ID #{vaccination_record_id} was not administered (Outcome: #{outcome})"
          return
        end

        fhir_record = vaccination_record.fhir_record
        fhir_json = fhir_record.to_json

        puts JSON.pretty_generate(JSON.parse(fhir_json))
      end
    end
  end

  register "vaccination-records" do |prefix|
    prefix.register "generate-fhir", VaccinationRecords::GenerateFHIR
  end
end
