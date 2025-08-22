# frozen_string_literal: true

module MavisCLI
  module Sessions
    class Delegation < Dry::CLI::Command
      desc "Configure delegation options in bulk"

      argument :workgroup, required: true, desc: "Workgroup of the team"
      argument :programme_type,
               required: true,
               desc: "Find sessions that administer this programme"

      option :psd,
             required: true,
             type: :boolean,
             desc: "Use patient specific direction (PSD)"
      option :national_protocol,
             required: true,
             type: :boolean,
             desc: "Use national protocol"

      def call(workgroup:, programme_type:, psd:, national_protocol:)
        MavisCLI.load_rails

        team = Team.find_by!(workgroup:)
        programme = Programme.find_by!(type: programme_type)

        team
          .sessions
          .includes(:location)
          .where(academic_year: AcademicYear.pending)
          .has_programmes([programme])
          .find_each do |session|
            session.psd_enabled = psd
            session.national_protocol_enabled = national_protocol

            if session.changed?
              session.save!
              puts "Updated #{session.slug}: #{session.location.name}"
            end
          end
      end
    end
  end

  register "sessions" do |prefix|
    prefix.register "delegation", Sessions::Delegation
  end
end
