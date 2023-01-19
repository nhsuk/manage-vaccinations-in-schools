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
# Indexes
#
#  index_children_on_nhs_number  (nhs_number) UNIQUE
#
require "rails_helper"

RSpec.describe Child, type: :model do
  pending "specs for age method"
end
