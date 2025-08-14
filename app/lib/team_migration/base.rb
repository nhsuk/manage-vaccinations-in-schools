# frozen_string_literal: true

class TeamMigration::Base
  def call
    ActiveRecord::Base.transaction { perform }
  end

  def self.call(...) = new(...).call

  private_class_method :new

  protected

  def log(message)
    # We use `puts` intentionally as this is a command line tool and the output
    # is more useful printed to the console like rather than logged and
    # converted to JSON.

    # rubocop:disable Rails/Output
    puts("#{ods_code}: #{message}")
    # rubocop:enable Rails/Output
  end

  def create_team(workgroup:, **attributes)
    log("Creating team #{workgroup}")
    team = organisation.teams.create!(workgroup:, **attributes)
    GenericClinicFactory.call(team:)
    team
  end

  def destroy_team(team)
    team.programmes.destroy_all
    team.subteams.destroy_all
    team.destroy!
  end

  def add_team_programmes(team, *programme_types)
    programme_types.each do |type|
      log("Adding #{type} programme to #{team.workgroup}")
      programme = Programme.find_by!(type:)
      team.programmes << programme
    end

    GenericClinicFactory.call(team:)
  end

  def set_team_workgroup(team, workgroup)
    log("Setting #{team.name} workgroup to #{workgroup}")
    team.update_column(:workgroup, workgroup)
  end

  def attach_school_to_subteam(location, subteam)
    log("Attaching #{location.urn} to #{subteam.name}")
    location.sessions.update_all(team_id: subteam.team_id)
    location.update!(subteam:)
  end

  def attach_school_to_team(location, team)
    attach_school_to_subteam(location, team.subteams.first)
  end

  def detach_school(urn:)
    log("Detaching #{urn}")
    Location.school.find_by!(urn:).update!(subteam_id: nil)
  end

  def add_school_year_groups(location, programmes, sen:)
    log(
      "Adding default #{programmes.map(&:name).to_sentence} year groups to #{location.urn}"
    )
    location.location_programme_year_groups.destroy_all
    location.create_default_programme_year_groups!(programmes)

    log("Adding additional flu year groups to #{location.urn}")
    if sen && (programme = programmes.find(&:flu?))
      location
        .year_groups
        .select { it >= 12 }
        .each do |year_group|
          location.location_programme_year_groups.create!(
            programme:,
            year_group:
          )
        end
    end
  end

  def organisation
    @organisation ||= Organisation.find_by!(ods_code:)
  end
end
