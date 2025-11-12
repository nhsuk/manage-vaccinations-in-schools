# frozen_string_literal: true

module MavisCLI
  module VaccinationRecords
    class BulkEdit < Dry::CLI::Command
      desc "Bulk edit vaccination records from CSV using the 'edit' command per row"

      option :file,
             required: true,
             desc:
               "Path to CSV file. Must include a header 'id' column for the record id; " \
                 "other columns are treated as attributes."

      option :csv,
             required: false,
             desc:
               "Raw CSV content as a string. Must include headers with 'id'."

      def call(file: nil, csv: nil, **)
        MavisCLI.load_rails

        if file.blank? && csv.blank?
          warn "Provide either --file or --csv"
          return
        end

        if file.present? && csv.present?
          warn "Provide only one of --file or --csv"
          return
        end

        enumerator =
          if csv.present?
            begin
              CSV.parse(csv, headers: true)
            rescue CSV::MalformedCSVError => e
              warn "Invalid CSV content: #{e.message}"
              return
            end
          else
            unless File.file?(file)
              warn "File not found: #{file}"
              return
            end
            CSV.foreach(file, headers: true)
          end

        enumerator.each_with_index do |row, idx|
          row_num = idx + 1
          id = row["id"]&.to_s&.strip
          if id.blank?
            warn "Row #{row_num}: missing id"
            next
          end

          # Build hash
          updates = {}
          row.headers.each do |header|
            next if header.nil?
            key = header.to_s
            next if key == "id"
            value = row[header]
            next if value&.to_s&.strip.blank?
            updates[key] = value
          end

          if updates.empty?
            puts "Row #{row_num} (id=#{id}): no updates provided, skipping"
            next
          end

          vaccination_record = ::VaccinationRecord.find_by(id:)
          if vaccination_record.nil?
            warn "Row #{row_num} (id=#{id}): vaccination record not found"
            next
          end

          begin
            ::VaccinationRecordTechnicalFieldsUpdater.call(
              vaccination_record: vaccination_record,
              updates: updates
            )
            puts "Row #{row_num} (id=#{id}): Successfully updated VaccinationRecord ##{id}"
          rescue StandardError => e
            warn "Row #{row_num} (id=#{id}): Error: #{e.message}"
          end
        end
      end
    end
  end

  register "vaccination-records" do |prefix|
    prefix.register "bulk-edit", VaccinationRecords::BulkEdit
  end
end
