# == Schema Information
#
# Table name: children
#
#  id             :bigint           not null, primary key
#  consent        :integer
#  dob            :date
#  first_name     :text
#  gp             :integer
#  last_name      :text
#  nhs_number     :bigint
#  preferred_name :text
#  screening      :integer
#  seen           :integer
#  sex            :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class Child < ApplicationRecord
  enum :gp, ["Local GP"]
  enum :screening, ["Approved for vaccination"]
  enum :consent, ["Parental consent (digital)"]
  enum :seen, ["Not yet"]

  has_and_belongs_to_many :campaigns

  def full_name
    "#{first_name} #{last_name}"
  end
end
