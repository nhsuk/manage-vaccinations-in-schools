class AddOneTimeTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :one_time_tokens, id: false do |t|
      t.references :user, foreign_key: { to_table: :users }
      t.string :token, null: false, primary_key: true
      t.timestamps
    end

    add_index :one_time_tokens, :token, unique: true
    add_index :one_time_tokens, :created_at
  end
end
