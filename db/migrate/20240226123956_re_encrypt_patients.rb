# frozen_string_literal: true

class ReEncryptPatients < ActiveRecord::Migration[7.1]
  def up
    Patient.find_each(&:encrypt)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
