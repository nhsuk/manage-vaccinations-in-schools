class CreateConsentForms < ActiveRecord::Migration[7.0]
  def change
    create_table :consent_forms do |t|
      t.references :session, null: false, foreign_key: true

      t.text :full_name
      t.text :common_name
      t.date :dob
      t.text :address_line_1
      t.text :address_line_2
      t.text :address_town
      t.text :address_postcode
      t.text :parent_name
      t.integer :parent_relationship
      t.text :parent_relationship_other
      t.text :parent_email
      t.text :parent_phone
      t.integer :parent_contact_method
      t.text :parent_contact_method_other
      t.integer :response
      t.integer :reason_for_refusal
      t.text :reason_for_refusal_other
      t.integer :gp_response
      t.text :gp_name
      t.integer :route, null: false
      t.jsonb :health_questions
      t.datetime :recorded_at

      t.timestamps
    end
  end
end
