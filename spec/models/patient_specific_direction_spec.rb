# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_specific_directions
#
#  id                 :bigint           not null, primary key
#  academic_year      :integer          not null
#  delivery_site      :integer          not null
#  invalidated_at     :datetime
#  programme_type     :enum             not null
#  vaccine_method     :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  created_by_user_id :bigint           not null
#  patient_id         :bigint           not null
#  team_id            :bigint           not null
#  vaccine_id         :bigint           not null
#
# Indexes
#
#  index_patient_specific_directions_on_academic_year       (academic_year)
#  index_patient_specific_directions_on_created_by_user_id  (created_by_user_id)
#  index_patient_specific_directions_on_patient_id          (patient_id)
#  index_patient_specific_directions_on_programme_type      (programme_type)
#  index_patient_specific_directions_on_team_id             (team_id)
#  index_patient_specific_directions_on_vaccine_id          (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_user_id => users.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (team_id => teams.id)
#  fk_rails_...  (vaccine_id => vaccines.id)
#
describe PatientSpecificDirection, type: :model do
  subject(:patient_specific_direction) { build(:patient_specific_direction) }

  describe "associations" do
    it do
      expect(patient_specific_direction).to belong_to(:created_by).class_name(
        "User"
      ).with_foreign_key(:created_by_user_id)
    end

    it { should belong_to(:patient) }
    it { should belong_to(:vaccine) }
  end

  describe "validations" do
    it do
      expect(patient_specific_direction).to validate_inclusion_of(
        :delivery_site
      ).in_array(
        %w[
          left_arm_upper_position
          left_arm_lower_position
          right_arm_upper_position
          right_arm_lower_position
          left_thigh
          right_thigh
          left_buttock
          right_buttock
          nose
        ]
      )
    end

    it do
      expect(patient_specific_direction).to validate_inclusion_of(
        :vaccine_method
      ).in_array(%w[injection nasal])
    end
  end
end
