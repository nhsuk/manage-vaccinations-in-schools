# frozen_string_literal: true

class AddResponseToConsentFormProgrammes < ActiveRecord::Migration[8.0]
  def change
    add_column :consent_form_programmes, :response, :integer

    # 0 = given
    # 1 = refused
    # 2 = given_one

    reversible do |dir|
      dir.up do
        ConsentFormProgramme
          .joins(:consent_form)
          .where(consent_forms: { response: 0 })
          .update_all(response: 0)

        ConsentFormProgramme
          .joins(:consent_form)
          .where(consent_forms: { response: 1 })
          .update_all(response: 1)

        ConsentFormProgramme
          .includes(:consent_form, :programme)
          .where(consent_forms: { response: 2 })
          .find_each do |consent_form_programme|
            consent_form = consent_form_programme.consent_form
            programme = consent_form_programme.programme

            next if consent_form.chosen_vaccine.blank?

            if programme.type == consent_form.chosen_vaccine
              consent_form_programme.update_column(:response, 0)
            else
              consent_form_programme.update_column(:response, 1)
            end
          end
      end
    end

    change_table :consent_forms, bulk: true do |t|
      t.remove :response, type: :integer
      t.remove :chosen_vaccine, type: :string
    end
  end
end
