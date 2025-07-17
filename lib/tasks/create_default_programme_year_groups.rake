# frozen_string_literal: true

desc "Ensures all existing organisations and locations have programme year groups."
task create_default_programme_year_groups: :environment do
  Organisation
    .includes(:programmes)
    .find_each do |organisation|
      year_groups =
        organisation.programmes.flat_map(&:default_year_groups).uniq.sort
      organisation.generic_clinic.update!(year_groups:)

      organisation.generic_clinic.create_default_programme_year_groups!(
        organisation.programmes
      )

      organisation.schools.find_each do |school|
        school.create_default_programme_year_groups!(organisation.programmes)
      end
    end
end
