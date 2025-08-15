# frozen_string_literal: true

# == Schema Information
#
# Table name: cohort_imports_parents
#
#  cohort_import_id :bigint           not null
#  parent_id        :bigint           not null
#
# Indexes
#
#  index_cohort_imports_parents_on_cohort_import_id_and_parent_id  (cohort_import_id,parent_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (cohort_import_id => cohort_imports.id)
#  fk_rails_...  (parent_id => parents.id)
#
class CohortImportsParent < ApplicationRecord
  belongs_to :cohort_import
  belongs_to :parent
end
