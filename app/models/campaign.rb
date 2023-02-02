# == Schema Information
#
# Table name: campaigns
#
#  id            :bigint           not null, primary key
#  date          :datetime
#  location_type :text
#  type          :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  location_id   :integer
#
class Campaign < ApplicationRecord
  self.inheritance_column = "__type"

  belongs_to :location, class_name: "School", optional: true
  has_and_belongs_to_many :children

  enum :type, ["HPV"]

  def title
    "#{type} campaign at #{location.name}"
  end
end
