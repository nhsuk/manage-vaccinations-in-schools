# frozen_string_literal: true

class DataMigration::SetTeamLocation
  def call
    models.each do |model|
      model.where(team_location_id: nil).find_each { handle_instance(it) }
    end
  end

  def self.call(...) = new(...).call

  private_class_method :new

  def models = [ConsentForm, Session]

  def handle_instance(instance)
    team_id = instance.team_id
    location_id = instance.location_id
    academic_year = instance.academic_year

    instance.update_column(
      :team_location_id,
      team_location_id(team_id, location_id, academic_year)
    )
  end

  def team_location_id(team_id, location_id, academic_year)
    @team_location_id = {}
    @team_location_id[team_id] ||= {}
    @team_location_id[team_id][location_id] ||= {}
    @team_location_id[team_id][location_id][
      academic_year
    ] ||= TeamLocation.find_or_create_by!(
      team_id:,
      location_id:,
      academic_year:
    ).id
  end
end
