# == Schema Information
#
# Table name: students
#
#  id         :bigint           not null, primary key
#  dob        :date
#  name       :string
#  nhs_number :decimal(, )
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Student < ApplicationRecord
end
