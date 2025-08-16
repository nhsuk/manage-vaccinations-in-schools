class AddLocalAuthority < ActiveRecord::Migration[8.0]
  def change
    create_table :local_authorities, id: false, primary_key: :local_authority_code do |t|
      t.string      :local_authority_code, null: false
      t.string      :gss_code
      t.integer     :gias_local_authority_code
      t.string      :official_name
      t.string      :short_name
      t.string      :gov_uk_slug
      t.string      :nation
      t.string      :region
      t.date        :end_date
      t.timestamps

      t.index :local_authority_code, unique: true
      t.index :gss_code, unique: true
      t.index :short_name
      t.index [:nation, :short_name]
      t.index :created_at
    end
  end
end
