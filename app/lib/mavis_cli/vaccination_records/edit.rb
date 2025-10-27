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

      ALLOWED_ATTRIBUTES = %w[
        confirmation_sent_at
        nhs_immunisations_api_etag
        nhs_immunisations_api_identifier_system
        nhs_immunisations_api_identifier_value
        nhs_immunisations_api_primary_source
        nhs_immunisations_api_sync_pending_at
        nhs_immunisations_api_synced_at
        source
        uuid
        created_at
        updated_at
        nhs_immunisations_api_id
        session_id
      ].freeze

      DATETIME_COLUMNS = %w[
        confirmation_sent_at
        nhs_immunisations_api_sync_pending_at
        nhs_immunisations_api_synced_at
        created_at
        updated_at
      ].freeze

      BOOLEAN_COLUMNS = %w[nhs_immunisations_api_primary_source].freeze

      INTEGER_COLUMNS = %w[patient_id session_id source].freeze

      def call(vaccination_record_id:, updates:, **)
        MavisCLI.load_rails

        record = ::VaccinationRecord.find_by(id: vaccination_record_id)
        if record.nil?
          raise "Vaccination record with ID #{vaccination_record_id} not found"
        end

        parsed_updates = {}
        errors = []

        updates.each do |pair|
          key, value = pair.split("=", 2)
          if value.nil?
            errors << "Invalid update '#{pair}'. Expected key=value."
            next
          end

          unless ALLOWED_ATTRIBUTES.include?(key)
            errors << "Attribute '#{key}' is not editable by this tool"
            next
          end

          begin
            parsed_updates[key] = coerce_value(key, value)
          rescue ArgumentError => e
            errors << "#{key}: #{e.message}"
          end
        end

        if errors.any?
          errors.each { |e| puts "Error: #{e}" }
          return
        end

        if parsed_updates.empty?
          puts "No valid updates provided"
          return
        end

        ActiveRecord::Base.transaction { record.update_columns(parsed_updates) }

        puts "Successfully updated VaccinationRecord ##{record.id}"
      end

      private

      def coerce_value(key, raw)
        return nil if raw.strip.casecmp("nil").zero?

        return Time.zone.parse(raw) if DATETIME_COLUMNS.include?(key)

        return to_bool(raw) if BOOLEAN_COLUMNS.include?(key)

        INTEGER_COLUMNS.include?(key) ? Integer(raw) : raw
      end

      def to_bool(val)
        case val.strip.downcase
        when "true", "1", "yes", "y"
          true
        when "false", "0", "no", "n"
          false
        else
          raise ArgumentError, "invalid boolean '#{val}'"
        end
      end
    end
  end

  register "vaccination-records" do |prefix|
    prefix.register "edit", VaccinationRecords::Edit
  end
end
