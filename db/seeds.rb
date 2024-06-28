# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

FEATURE_FLAGS = %i[make_session_in_progress_button].freeze

FEATURE_FLAGS.each { |flag| Flipper.add(flag) unless Flipper.exist?(flag) }

if Settings.disallow_database_seeding
  Rails.logger.info "Database seeding is disabled"
  exit
end

Faker::Config.locale = "en-GB"

user =
  User.find_by(email: "nurse.joy@example.com") ||
    FactoryBot.create(
      :user,
      full_name: "Nurse Joy",
      email: "nurse.joy@example.com",
      password: "nurse.joy@example.com"
    )
Audited
  .audit_class
  .as_user(user) do
    FactoryBot.create(
      :example_campaign,
      :in_progress,
      :in_past,
      :in_future,
      :hpv,
      user:
    )
  end
