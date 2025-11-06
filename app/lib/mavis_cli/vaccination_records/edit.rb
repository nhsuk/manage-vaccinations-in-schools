# frozen_string_literal: true

module MavisCLI
  module VaccinationRecords
    class Edit < Dry::CLI::Command
      desc "Edit only technically functional fields on a vaccination record"

      argument :vaccination_record_id,
               required: true,
               desc: "ID of vaccination record to edit"

      argument :updates,
               type: :array,
               required: true,
               desc:
                 "One or more key=value pairs to update (e.g., uuid=... source=0)"

      def call(vaccination_record_id:, updates:, **)
        MavisCLI.load_rails

        vaccination_record =
          ::VaccinationRecord.find_by(id: vaccination_record_id)
        if vaccination_record.nil?
          raise "Vaccination record with ID #{vaccination_record_id} not found"
        end

        # Parse key=value pairs from CLI into a hash
        parsed = {}
        updates.each do |pair|
          key, value = pair.split("=", 2)
          raise "Invalid update '#{pair}'. Expected key=value." if value.nil?
          parsed[key] = value
        end

        begin
          ::VaccinationRecordTechnicalFieldsUpdater.call(
            vaccination_record: vaccination_record,
            updates: parsed
          )
        rescue StandardError => e
          puts "Error: #{e.message}"
          return
        end

        puts "Successfully updated VaccinationRecord ##{vaccination_record.id}"
      end
    end
  end

  register "vaccination-records" do |prefix|
    prefix.register "edit", VaccinationRecords::Edit
  end
end
