# == Schema Information
#
# Table name: schools
#
#  id            :bigint           not null, primary key
#  address       :text
#  county        :text
#  detailed_type :text
#  locality      :text
#  maximum_age   :decimal(, )
#  minimum_age   :decimal(, )
#  name          :text
#  phase         :integer
#  postcode      :text
#  town          :text
#  type          :text
#  url           :text
#  urn           :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_schools_on_urn  (urn) UNIQUE
#
class School < ApplicationRecord
  self.inheritance_column = "__type"

  has_one :campaign

  enum :phase, ["Primary"]
end
