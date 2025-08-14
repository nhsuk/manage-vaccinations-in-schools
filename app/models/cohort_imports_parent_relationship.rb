# frozen_string_literal: true

# == Schema Information
#
# Table name: cohort_imports_parent_relationships
#
#  cohort_import_id       :bigint           not null
#  parent_relationship_id :bigint           not null
#
# Indexes
#
#  idx_on_cohort_import_id_parent_relationship_id_c65e20d1f8  (cohort_import_id,parent_relationship_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (cohort_import_id => cohort_imports.id)
#  fk_rails_...  (parent_relationship_id => parent_relationships.id)
#
class CohortImportsParentRelationship < ApplicationRecord
  belongs_to :cohort_import
  belongs_to :parent_relationship
end
