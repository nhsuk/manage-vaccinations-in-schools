# frozen_string_literal: true

namespace :teams do
  desc "Add a programme to an team."
  task :add_programme, %i[ods_code type] => :environment do |_task, args|
    team = Team.find_by!(ods_code: args[:ods_code])
    programme = Programme.find_by!(type: args[:type])

    TeamProgramme.find_or_create_by!(team:, programme:)

    GenericClinicFactory.call(team: team.reload)
  end
end
