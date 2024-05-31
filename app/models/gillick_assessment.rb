# == Schema Information
#
# Table name: gillick_assessments
#
#  id                 :bigint           not null, primary key
#  gillick_competent  :boolean
#  notes              :text
#  recorded_at        :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  assessor_user_id   :bigint           not null
#  patient_session_id :bigint           not null
#
# Indexes
#
#  index_gillick_assessments_on_assessor_user_id    (assessor_user_id)
#  index_gillick_assessments_on_patient_session_id  (patient_session_id)
#
# Foreign Keys
#
#  fk_rails_...  (assessor_user_id => users.id)
#  fk_rails_...  (patient_session_id => patient_sessions.id)
#
class GillickAssessment < ApplicationRecord
  belongs_to :patient_session
  belongs_to :assessor, class_name: "User", foreign_key: :assessor_user_id

  encrypts :notes
end
