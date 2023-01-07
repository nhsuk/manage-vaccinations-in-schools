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
require 'rails_helper'

RSpec.describe Child, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
