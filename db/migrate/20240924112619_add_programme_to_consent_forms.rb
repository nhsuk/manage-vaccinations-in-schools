# frozen_string_literal: true

class AddProgrammeToConsentForms < ActiveRecord::Migration[7.2]
  def up
    add_reference :consent_forms, :programme, foreign_key: true

    ConsentForm.find_each do |consent_form|
      consent_form.update!(
        programme_id: (consent_form.session.programme || Programme.first).id
      )
    end

    change_column_null :consent_forms, :programme_id, false
  end

  def down
    remove_reference :consent_forms, :programme
  end
end
