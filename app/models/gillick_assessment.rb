# frozen_string_literal: true

# == Schema Information
#
# Table name: gillick_assessments
#
#  id                 :bigint           not null, primary key
#  gillick_competent  :boolean
#  location_name      :string
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
  include LocationNameConcern
  include Recordable
  include WizardStepConcern

  audited

  belongs_to :patient_session
  belongs_to :assessor, class_name: "User", foreign_key: :assessor_user_id

  has_one :patient, through: :patient_session
  has_one :session, through: :patient_session
  has_one :location, through: :session

  encrypts :notes

  on_wizard_step :gillick do
    validates :gillick_competent, inclusion: { in: [true, false] }
  end

  on_wizard_step :location, exact: true do
    validates :location_name, presence: true
  end

  on_wizard_step :notes do
    validates :notes, length: { maximum: 1000 }, presence: true
  end

  def wizard_steps
    [:gillick, (:location if requires_location_name?), :notes, :confirm].compact
  end
end
