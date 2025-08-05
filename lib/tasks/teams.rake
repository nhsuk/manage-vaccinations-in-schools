# frozen_string_literal: true

namespace :teams do
  desc "Add a programme to a team."
  task :add_programme, %i[ods_code type] => :environment do |_task, args|
    # TODO: Select the right team based on an identifier.
    team =
      Team.joins(:organisation).find_by!(
        organisation: {
          ods_code: args[:ods_code]
        }
      )
    programme = Programme.find_by!(type: args[:type])

    TeamProgramme.find_or_create_by!(team:, programme:)

    GenericClinicFactory.call(team: team.reload)
  end
end
