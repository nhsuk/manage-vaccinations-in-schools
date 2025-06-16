# frozen_string_literal: true

class AddResponseToConsentFormProgrammes < ActiveRecord::Migration[8.0]
  # 0 = given
  # 1 = refused
  # 2 = given_one

  def up
    add_column :consent_form_programmes, :response, :integer

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

    change_table :consent_forms, bulk: true do |t|
      t.remove :response
      t.remove :chosen_vaccine
    end
  end

  def down
    change_table :consent_forms, bulk: true do |t|
      t.integer :response
      t.string :chosen_vaccine
    end

    ConsentForm
      .includes(consent_form_programmes: :programme)
      .find_each do |consent_form|
        consent_form_programmes = consent_form.consent_form_programmes

        if consent_form_programmes.all?(&:response_given?)
          consent_form.update_column(:response, 0)
        elsif consent_form_programmes.all?(&:response_refused?)
          consent_form.update_column(:response, 1)
        elsif consent_form_programmes.none? { it.response.nil? }
          chosen_vaccine =
            consent_form_programmes.find(&:response_given?).programme.type
          consent_form.update_columns(response: 2, chosen_vaccine:)
        end
      end

    remove_column :consent_form_programmes, :response
  end
end
