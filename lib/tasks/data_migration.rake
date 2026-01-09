# frozen_string_literal: true

namespace :data_migration do
  desc "Set disease types on all pre-screenings."
  task set_pre_screening_disease_types: :environment do
    PreScreening
      .where(disease_types: nil)
      .find_each do |pre_screening|
        programme = Programme.find(pre_screening.programme_type)

        disease_types =
          if programme.mmr?
            Programme::Variant::DISEASE_TYPES.fetch("mmr")
          else
            programme.disease_types
          end

        pre_screening.update_columns(disease_types:)
      end
  end
end
