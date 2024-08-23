# frozen_string_literal: true

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
  include Recordable
  include WizardFormConcern

  audited

  belongs_to :patient_session
  belongs_to :assessor, class_name: "User", foreign_key: :assessor_user_id

  encrypts :notes

  on_wizard_step :gillick do
    validates :gillick_competent, inclusion: { in: [true, false] }
  end

  on_wizard_step :notes do
    validates :notes, length: { maximum: 1000 }, presence: true
  end

  def self.form_steps
    %i[gillick notes confirm]
  end

  def form_steps
    self.class.form_steps
  end
end
