# frozen_string_literal: true

module MavisCLI
  module VaccinationRecords
    class CreateFromFHIR < Dry::CLI::Command
      desc "Create a vaccination record from a FHIR Immunization JSON"

      argument :patient_id,
               required: true,
               desc: "ID of the patient to attach the vaccination record to"

      option :file,
             type: :string,
             required: false,
             desc: "Path to a file containing the FHIR Immunization JSON"
      option :json,
             type: :string,
             required: false,
             desc: "Raw FHIR Immunization JSON string"

      def call(patient_id:, file: nil, json: nil, **)
        MavisCLI.load_rails

        unless Flipper.enabled?(:immunisations_fhir_api_integration)
          puts "Error: Feature flag :immunisations_fhir_api_integration is not enabled"
          return
        end

        unless Flipper.enabled?(:immunisations_fhir_api_integration_search)
          puts "Error: Feature flag :immunisations_fhir_api_integration_search is not enabled"
          return
        end

        if file.blank? && json.blank?
          puts "Error: Provide either --file PATH or --json STRING"
          return
        end

        if file.present? && json.present?
          puts "Error: Provide only one of --file or --json"
          return
        end

        patient = Patient.find_by(id: patient_id)
        if patient.nil?
          puts "Error: Patient with ID #{patient_id} not found"
          return
        end

        begin
          payload = file ? File.read(file) : json
          data = JSON.parse(payload)
        rescue Errno::ENOENT
          puts "Error: File not found: #{file}"
          return
        rescue JSON::ParserError => e
          puts "Error: Invalid JSON - #{e.message}"
          return
        end

        begin
          fhir_record = FHIR::Immunization.new(data)
        rescue StandardError => e
          puts "Error: Could not build FHIR::Immunization - #{e.message}"
          return
        end

        begin
          record =
            FHIRMapper::VaccinationRecord.from_fhir_record(
              fhir_record,
              patient: patient
            )

          record.save!
          puts "Created vaccination record #{record.id}"
        rescue ActiveRecord::RecordInvalid => e
          puts "Error: Could not save VaccinationRecord - #{e.record.errors.full_messages.join(", ")}"
        rescue StandardError => e
          puts "Error: #{e.message}"
        end
      end
    end
  end

  register "vaccination-records" do |prefix|
    prefix.register "create-from-fhir", VaccinationRecords::CreateFromFHIR
  end
end
