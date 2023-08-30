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
  attr_accessor :is_this_their_school

  audited

  belongs_to :session

  validates :first_name, presence: true, on: :edit_name
  validates :last_name, presence: true, on: :edit_name
  validates :use_common_name, inclusion: { in: [true, false] }, on: :edit_name
  validates :common_name, presence: true, on: :edit_name, if: :use_common_name?
  validates :date_of_birth,
            presence: true,
            comparison: {
              less_than: Time.zone.today,
              greater_than_or_equal_to: 22.years.ago.to_date,
              less_than_or_equal_to: 3.years.ago.to_date
            },
            on: :edit_date_of_birth
  validates :is_this_their_school,
            presence: true,
            inclusion: {
              in: %w[yes no]
            },
            on: :edit_school

  def full_name
    [first_name, last_name].join(" ")
  end
end
