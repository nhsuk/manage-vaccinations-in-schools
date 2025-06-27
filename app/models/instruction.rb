# frozen_string_literal: true

# == Schema Information
#
# Table name: instructions
#
#  id                 :bigint           not null, primary key
#  delivery_site      :string           not null
#  full_dose          :boolean          not null
#  protocol           :string           not null
#  vaccine_method     :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  created_by_user_id :bigint           not null
#  patient_id         :bigint           not null
#  programme_id       :bigint           not null
#  vaccine_id         :bigint           not null
#
# Indexes
#
#  index_instructions_on_created_by_user_id  (created_by_user_id)
#  index_instructions_on_patient_id          (patient_id)
#  index_instructions_on_programme_id        (programme_id)
#  index_instructions_on_vaccine_id          (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_user_id => users.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (vaccine_id => vaccines.id)
#
class Instruction < ApplicationRecord
  belongs_to :created_by, class_name: "User", foreign_key: :created_by_user_id
  belongs_to :patient
  belongs_to :programme
  belongs_to :vaccine

  validates :delivery_site, presence: true
  validates :vaccine_method, presence: true
  validates :protocol, presence: true
  validates :full_dose, inclusion: { in: [true, false] }
end
