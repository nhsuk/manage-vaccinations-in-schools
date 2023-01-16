# == Schema Information
#
# Table name: campaigns
#
#  id            :bigint           not null, primary key
#  date          :datetime
#  location_type :text
#  title         :text
#  type          :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  location_id   :integer
#
class Campaign < ApplicationRecord
  self.inheritance_column = '__type'

  belongs_to :location, class_name: 'School'
  has_and_belongs_to_many :children

  enum :type, ['HPV']
end
