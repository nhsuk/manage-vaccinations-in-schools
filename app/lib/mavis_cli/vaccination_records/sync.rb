# frozen_string_literal: true

module MavisCLI
  module VaccinationRecords
    class Sync < Dry::CLI::Command
      desc "Sync a vaccination record to NHSE Immunisations API"
      argument :vaccination_record_id,
               required: true,
               desc: "ID of vaccination record to sync"

      def call(vaccination_record_id:, **)
        MavisCLI.load_rails

        vaccination_record =
          ::VaccinationRecord.find_by(id: vaccination_record_id)

        if vaccination_record.nil?
          puts "Vaccination record with ID #{vaccination_record_id} not found"
          return
        end

        if vaccination_record.nhse_synced_at.present?
          puts "Vaccination record #{vaccination_record_id} has already been" \
                 " synced at #{vaccination_record.nhse_synced_at}"
          return
        end

        SyncVaccinationRecordToNHSEJob.perform_now(vaccination_record)
        puts "Successfully synced vaccination record #{vaccination_record_id}"
      end
    end
  end

  register "vaccination-records" do |prefix|
    prefix.register "sync", VaccinationRecords::Sync
  end
end
