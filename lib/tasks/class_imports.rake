# frozen_string_literal: true

namespace :class_imports do
  desc "Assign year groups to class imports without them."
  task assign_year_groups: :environment do
    ClassImport
      .includes(session: :programmes)
      .where(year_groups: [])
      .find_each do |class_import|
        year_groups = class_import.session.year_groups
        class_import.update_column(:year_groups, year_groups)
      end
  end
end
