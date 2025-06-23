# frozen_string_literal: true

# == Schema Information
#
# Table name: notes
#
#  id                 :bigint           not null, primary key
#  body               :text             not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  created_by_user_id :bigint           not null
#  patient_id         :bigint           not null
#  session_id         :bigint           not null
#
# Indexes
#
#  index_notes_on_created_by_user_id  (created_by_user_id)
#  index_notes_on_patient_id          (patient_id)
#  index_notes_on_session_id          (session_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_user_id => users.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (session_id => sessions.id)
#
class Note < ApplicationRecord
  belongs_to :created_by, class_name: "User", foreign_key: :created_by_user_id
  belongs_to :patient
  belongs_to :session

  has_one :organisation, through: :session

  validates :body, presence: true, length: { maximum: 1000 }

  def programmes
    session.programmes.select { it.year_groups.include?(year_group) }
  end

  private

  def year_group = patient.year_group(now: created_at.to_date)
end
