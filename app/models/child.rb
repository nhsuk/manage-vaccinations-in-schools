# == Schema Information
#
# Table name: children
#
#  id         :bigint           not null, primary key
#  dob        :date
#  name       :string
#  nhs_number :decimal(, )
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Child < ApplicationRecord
end
