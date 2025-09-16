# frozen_string_literal: true

# == Schema Information
#
# Table name: attendance_records
#
#  id          :bigint           not null, primary key
#  attending   :boolean          not null
#  date        :date             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  location_id :bigint           not null
#  patient_id  :bigint           not null
#
# Indexes
#
#  idx_on_patient_id_location_id_date_e5912f40c4  (patient_id,location_id,date) UNIQUE
#  index_attendance_records_on_location_id        (location_id)
#  index_attendance_records_on_patient_id         (patient_id)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id)
#  fk_rails_...  (patient_id => patients.id)
#
describe AttendanceRecord do
  subject(:attendance_record) { build(:attendance_record) }

  describe "associations" do
    it { should belong_to(:patient) }
    it { should belong_to(:location) }
  end
end
