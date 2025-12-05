# frozen_string_literal: true

namespace :data_migrations do
  desc "Encrypt all the note body values."
  task encrypt_note_body: :environment do
    Note.find_each(&:encrypt)
  end
end
