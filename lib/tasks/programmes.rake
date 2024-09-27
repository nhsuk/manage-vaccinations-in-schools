# frozen_string_literal: true

namespace :programmes do
  desc "Create a new programme for a team."
  task :create, %i[type] => :environment do |_, args|
    team = Team.find_by(id: args[:team_id])
    type = args[:type]

    raise "Could not find team." if team.nil?
    raise "Invalid type." unless %w[flu hpv].include?(type)

    if Programme.exists?(type:)
      raise "A programme of this type already exists for this team."
    end

    vaccines = Vaccine.active.where(type:).to_a

    raise "There are no vaccines for this type of programme." if vaccines.empty?

    programme = Programme.create!(type:, vaccines:)

    puts "New #{programme.name} programme with ID #{programme.id} created."
    puts "Vaccines: #{vaccines.map(&:brand).join(", ")}"
  end
end
