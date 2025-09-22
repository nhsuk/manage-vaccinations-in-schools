# frozen_string_literal: true

class EncryptConsentFormNotes < ActiveRecord::Migration[8.0]
  def up
    ConsentForm.find_each(&:encrypt)
  end
end
