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
  has_one :patient

  enum :relationship, %w[mother father guardian other], prefix: true

  encrypts :email, :name, :phone, :relationship_other

  def relationship_label
    if relationship == "other"
      relationship_other
    else
      human_enum_name(:relationship)
    end.capitalize
  end
end
