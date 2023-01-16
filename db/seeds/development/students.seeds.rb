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
#!/usr/bin/env ruby

CHILDREN_DATA = <<EODATA.freeze
- id: 1
  name: Isaiah Fay
  dob: 2013-05-10
  nhs_number: 6304268263
EODATA

children_data = YAML.unsafe_load(CHILDREN_DATA)
Child.transaction do
  children_data.each do |child_data|
    Child.find_or_create_by(**child_data)
  end
end
