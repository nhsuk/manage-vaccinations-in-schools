# frozen_string_literal: true

# == Schema Information
#
# Table name: parent_relationships
#
#  id         :bigint           not null, primary key
#  other_name :string
#  type       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  parent_id  :bigint           not null
#  patient_id :bigint           not null
#
# Indexes
#
#  index_parent_relationships_on_parent_id                 (parent_id)
#  index_parent_relationships_on_parent_id_and_patient_id  (parent_id,patient_id) UNIQUE
#  index_parent_relationships_on_patient_id                (patient_id)
#
# Foreign Keys
#
#  fk_rails_...  (parent_id => parents.id)
#  fk_rails_...  (patient_id => patients.id)
#
class ParentRelationship < ApplicationRecord
  audited

  self.inheritance_column = nil

  belongs_to :parent
  belongs_to :patient

  has_and_belongs_to_many :cohort_imports

  enum :type,
       {
         father: "father",
         guardian: "guardian",
         mother: "mother",
         other: "other"
       },
       validate: true

  encrypts :other_name

  validates :other_name, presence: true, length: { maximum: 300 }, if: :other?

  before_validation -> { self.other_name = nil unless other? }

  def label
    (other? ? other_name : human_enum_name(:type)).capitalize
  end
end
