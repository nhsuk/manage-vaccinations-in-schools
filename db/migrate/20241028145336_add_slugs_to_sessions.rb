class AddSlugsToSessions < ActiveRecord::Migration[7.2]
  def change
    add_column :sessions, :slug, :string

    Session.find_each do |session|
      session.update!(slug: SecureRandom.alphanumeric(10))
    end

    change_column_null :sessions, :slug, false
  end
end
