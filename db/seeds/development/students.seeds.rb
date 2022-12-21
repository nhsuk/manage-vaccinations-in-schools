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
#!/usr/bin/env ruby

STUDENTS_DATA = <<EODATA
- id: 1
  name: Isaiah Fay
  dob: 2013-05-10
  nhs_number: 6304268263
EODATA

students_data = YAML.unsafe_load(STUDENTS_DATA)
Student.transaction do
  students_data.each do |student_data|
    Student.find_or_create_by(**student_data)
  end
end
