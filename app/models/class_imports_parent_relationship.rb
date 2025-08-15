# frozen_string_literal: true

# == Schema Information
#
# Table name: class_imports_parent_relationships
#
#  class_import_id        :bigint           not null
#  parent_relationship_id :bigint           not null
#
# Indexes
#
#  idx_on_class_import_id_parent_relationship_id_8225058195  (class_import_id,parent_relationship_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (class_import_id => class_imports.id)
#  fk_rails_...  (parent_relationship_id => parent_relationships.id)
#
class ClassImportsParentRelationship < ApplicationRecord
  belongs_to :class_import
  belongs_to :parent_relationship
end
