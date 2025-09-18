# frozen_string_literal: true

# == Schema Information
#
# Table name: class_imports_parents
#
#  class_import_id :bigint           not null
#  parent_id       :bigint           not null
#
# Indexes
#
#  index_class_imports_parents_on_class_import_id_and_parent_id  (class_import_id,parent_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (class_import_id => class_imports.id) ON DELETE => cascade
#  fk_rails_...  (parent_id => parents.id) ON DELETE => cascade
#
class ClassImportsParent < ApplicationRecord
  belongs_to :class_import
  belongs_to :parent
end
