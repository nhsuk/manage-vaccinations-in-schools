# frozen_string_literal: true

namespace :data_migration do
  desc "Set disease types on vaccination records."
  task set_disease_types: :environment do
    VaccinationRecord
      .includes(:vaccine)
      .where(disease_types: nil)
      .find_each do |vaccination_record|
        disease_types =
          vaccination_record.vaccine&.disease_types ||
            vaccination_record.programme.disease_types
        vaccination_record.update_columns(disease_types:)
      end
  end
end
