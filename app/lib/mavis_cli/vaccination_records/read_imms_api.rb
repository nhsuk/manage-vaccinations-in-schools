# frozen_string_literal: true

module MavisCLI
  module VaccinationRecords
    class ReadImmsAPI < Dry::CLI::Command
      desc "Read a vaccination record from the NHS Immunisations API"

      option :vaccination_record_id,
             required: false,
             desc: "Mavis ID of the vaccination record"
      option :imms_api_id,
             required: false,
             desc: "The Imms API ID of the vaccination record"
      option :output_file,
             required: false,
             desc: "File path to save JSON output"

      def call(
        vaccination_record_id: nil,
        imms_api_id: nil,
        output_file: nil,
        **
      )
        MavisCLI.load_rails

        unless Flipper.enabled?(:imms_api_integration)
          puts "Cannot read: Feature flag :imms_api_integration is not enabled"
          return
        end

        if vaccination_record_id.blank? && imms_api_id.blank?
          puts "Error: Provide either --vaccination-record-id or --imms-api-id"
          return
        end

        if vaccination_record_id.present? && imms_api_id.present?
          puts "Error: Provide only one of --vaccination-record-id or --imms-api-id"
          return
        end

        if imms_api_id.present?
          fhir_record =
            NHS::ImmunisationsAPI.read_immunisation_by_nhs_immunisations_api_id(
              imms_api_id
            )
        else
          vaccination_record =
            VaccinationRecord.find_by(id: vaccination_record_id)
          if vaccination_record.nil?
            puts "Error: Vaccination record with ID #{vaccination_record_id} not found in Mavis"
            return
          end

          fhir_record =
            NHS::ImmunisationsAPI.read_immunisation(vaccination_record)
        end

        if fhir_record.nil?
          puts "No result returned"
          return
        end

        json = fhir_record.to_json
        pretty = JSON.pretty_generate(JSON.parse(json))

        if output_file && !output_file.strip.empty?
          File.write(output_file, pretty)
          puts "Saved JSON to #{output_file}"
        else
          puts pretty
        end
      end
    end
  end

  register "vaccination-records" do |prefix|
    prefix.register "read-imms-api", VaccinationRecords::ReadImmsAPI
  end
end
