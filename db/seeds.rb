# frozen_string_literal: true

FEATURE_FLAGS = %i[dev_tools mesh_jobs].freeze

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
      family_name: "Joy",
      given_name: "Nurse",
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

Team.find_by(ods_code: "Y51") ||
  FactoryBot.create(:team, name: "NMEPFIT SAIS Team", ods_code: "Y51")

Rake::Task["vaccines:seed"].execute

Rake::Task["schools:import"].execute
