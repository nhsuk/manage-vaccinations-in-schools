# frozen_string_literal: true

class CreateConsentResponses < ActiveRecord::Migration[7.0]
  def change
    create_table :consent_responses do |t|
      t.references :patient, null: false, foreign_key: true
      t.references :campaign, null: false, foreign_key: true

      t.text :childs_name
      t.text :childs_common_name
      t.date :childs_dob
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
      t.integer :consent
      t.integer :reason_for_refusal
      t.text :reason_for_refusal_other
      t.integer :gp_response
      t.text :gp_name
      t.integer :route, null: false

      t.timestamps
    end
  end
end
