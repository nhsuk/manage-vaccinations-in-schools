# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

FEATURE_FLAGS = %i[make_session_in_progress_button new_consents].freeze

FEATURE_FLAGS.each { |flag| Flipper.add(flag) unless Flipper.exist?(flag) }
