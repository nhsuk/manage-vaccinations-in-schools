# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

FEATURE_FLAGS = {
  make_session_in_progress_button: false,
  basic_auth: Rails.env.staging? || Rails.env.production?
}.freeze

FEATURE_FLAGS.each do |flag, default|
  next if Flipper.exist?(flag)

  case default
  when true
    Flipper.enable flag
  when false
    Flipper.disable flag
  else
    raise "Invalid default value for #{flag}: #{default.inspect}"
  end
end
