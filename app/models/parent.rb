# == Schema Information
#
# Table name: parents
#
#  id                   :bigint           not null, primary key
#  contact_method       :integer
#  contact_method_other :text
#  email                :string
#  name                 :string
#  phone                :string
#  relationship         :integer
#  relationship_other   :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
class Parent < ApplicationRecord
  audited

  has_one :patient

  enum :relationship, %w[mother father guardian other], prefix: true

  encrypts :email, :name, :phone, :relationship_other

  validates :name, presence: true
  validates :phone, presence: true, phone: true
  validates :email, email: true
  validates :relationship,
            inclusion: {
              in: Parent.relationships.keys
            },
            presence: true
  validates :relationship_other,
            presence: true,
            if: -> { relationship == "other" }

  validates :contact_method_other,
            :email,
            :name,
            :phone,
            :relationship_other,
            length: {
              maximum: 300
            }

  def relationship_label
    if relationship == "other"
      relationship_other
    else
      human_enum_name(:relationship)
    end.capitalize
  end
end
