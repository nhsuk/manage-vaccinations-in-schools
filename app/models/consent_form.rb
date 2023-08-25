# == Schema Information
#
# Table name: consent_forms
#
#  id              :bigint           not null, primary key
#  common_name     :text
#  date_of_birth   :date
#  first_name      :text
#  last_name       :text
#  recorded_at     :datetime
#  use_common_name :boolean
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  session_id      :bigint           not null
#
# Indexes
#
#  index_consent_forms_on_session_id  (session_id)
#
# Foreign Keys
#
#  fk_rails_...  (session_id => sessions.id)
#

class ConsentForm < ApplicationRecord
  audited

  belongs_to :session

  validates :first_name, presence: true, on: :edit_name
  validates :last_name, presence: true, on: :edit_name
  validates :use_common_name, inclusion: { in: [true, false] }, on: :edit_name
  validates :common_name, presence: true, on: :edit_name, if: :use_common_name?

  def full_name
    [first_name, last_name].join(" ")
  end
end
