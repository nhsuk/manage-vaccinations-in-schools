# frozen_string_literal: true

module MavisCLI
  module Sessions
    class Configure < Dry::CLI::Command
      desc "Configure options in bulk"

      argument :workgroup, required: true, desc: "Workgroup of the team"
      argument :programme_type,
               required: true,
               desc: "Find sessions that administer this programme"

      option :requires_registration,
             type: :boolean,
             desc: "Whether the session requires registration"
      option :psd_enabled,
             type: :boolean,
             desc: "Use patient specific direction (PSD)"
      option :national_protocol_enabled,
             type: :boolean,
             desc: "Use national protocol"

      def call(
        workgroup:,
        programme_type:,
        requires_registration: nil,
        psd_enabled: nil,
        national_protocol_enabled: nil
      )
        MavisCLI.load_rails

        team = Team.find_by!(workgroup:)
        programme = Programme.find_by!(type: programme_type)

        attributes = {
          requires_registration:,
          psd_enabled:,
          national_protocol_enabled:
        }.compact

        team
          .sessions
          .includes(:location)
          .where(academic_year: AcademicYear.pending)
          .has_all_programmes_of([programme])
          .find_each do |session|
            session.assign_attributes(attributes)

            if session.changed?
              session.save!
              puts "Updated #{session.slug}: #{session.location.name}"
            end
          end
      end
    end
  end

  register "sessions" do |prefix|
    prefix.register "configure", Sessions::Configure
  end
end
