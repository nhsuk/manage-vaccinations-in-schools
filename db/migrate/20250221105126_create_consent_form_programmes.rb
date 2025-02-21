# frozen_string_literal: true

class CreateConsentFormProgrammes < ActiveRecord::Migration[8.0]
  def up
    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table :consent_form_programmes do |t|
      t.references :programme, foreign_key: true, null: false
      t.references :consent_form, foreign_key: true, null: false
      t.index %i[programme_id consent_form_id], unique: true
    end
    # rubocop:enable Rails/CreateTableWithTimestamps

    ConsentForm
      .pluck(:id, :programme_id)
      .each do |consent_form_id, programme_id|
        ConsentFormProgramme.create!(consent_form_id:, programme_id:)
      end

    remove_reference :consent_forms, :programme
  end

  def down
    add_reference :consent_forms, :programme, foreign_key: true

    ConsentForm
      .includes(:consent_form_programmes)
      .find_each do |consent_form|
        consent_form.update_column(
          :programme_id,
          consent_form.consent_form_programmes.first.programme_id
        )
      end

    change_column_null :consent_forms, :programme_id, false

    drop_table :consent_form_programmes
  end
end
