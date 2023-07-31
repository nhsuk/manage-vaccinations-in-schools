# == Schema Information
#
# Table name: locations
#
#  id         :bigint           not null, primary key
#  address    :text
#  county     :text
#  locality   :text
#  name       :text
#  postcode   :text
#  town       :text
#  url        :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Location < ApplicationRecord
  audited

  has_many :sessions
  has_many :patients

  validates :name, presence: true
end
