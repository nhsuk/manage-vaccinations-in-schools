# frozen_string_literal: true

module MavisCLI
  module VaccinationRecords
    class SearchImmsAPI < Dry::CLI::Command
      desc "Search vaccination records in NHS Immunisations API for a patient"

      argument :patient_id, required: true, desc: "ID of the patient"
      argument :programme_types,
               type: :array,
               required: false,
               desc: "The programme types to search for"
      option :date_from, required: false, desc: "Start date (YYYY-MM-DD)"
      option :date_to, required: false, desc: "End date (YYYY-MM-DD)"
      option :output_file,
             required: false,
             desc: "File path to save JSON output"

      def call(
        patient_id:,
        programme_types:,
        date_from: nil,
        date_to: nil,
        output_file: nil,
        **
      )
        MavisCLI.load_rails

        unless Flipper.enabled?(:imms_api_integration)
          puts "Cannot search: Feature flag :imms_api_integration is not enabled"
          return
        end

        patient = Patient.find_by(id: patient_id)
        if patient.nil?
          puts "Error: Patient with ID #{patient_id} not found"
          return
        end

        programmes =
          if programme_types.empty?
            Programme.can_search_in_immunisations_api
          else
            programme_types.map do |type|
              Programme.find_by(type: type.downcase)
            end
          end
        if programmes.any?(&:nil?)
          puts "Error: One or more programmes not found in database; " \
                 "available types are: #{Programme.types.keys.join(", ")}"
          return
        end

        from_date = parse_date_opt(date_from, "DATE_FROM")
        return if from_date == :error
        to_date = parse_date_opt(date_to, "DATE_TO")
        return if to_date == :error

        if from_date && to_date && from_date > to_date
          puts "Error: DATE_FROM cannot be after DATE_TO"
          return
        end

        bundle =
          NHS::ImmunisationsAPI.search_immunisations(
            patient,
            programmes: programmes,
            date_from: from_date,
            date_to: to_date
          )

        if bundle.nil?
          puts "No result returned"
          return
        end

        json = bundle.to_json
        pretty = JSON.pretty_generate(JSON.parse(json))

        if output_file && !output_file.strip.empty?
          File.write(output_file, pretty)
          puts "Saved JSON to #{output_file}"
        else
          puts pretty
        end
      end

      private

      def parse_date_opt(value, name)
        return nil if value&.strip.blank?
        Date.parse(value)
      rescue ArgumentError
        puts "Error: Invalid #{name} format '#{value}'. Expected YYYY-MM-DD."
        :error
      end
    end
  end

  register "vaccination-records" do |prefix|
    prefix.register "search-imms-api", VaccinationRecords::SearchImmsAPI
  end
end
