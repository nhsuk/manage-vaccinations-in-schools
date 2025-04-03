# frozen_string_literal: true

# == Schema Information
#
# Table name: pre_screenings
#
#  id                    :bigint           not null, primary key
#  feeling_well          :boolean          not null
#  knows_vaccination     :boolean          not null
#  no_allergies          :boolean          not null
#  not_already_had       :boolean          not null
#  not_pregnant          :boolean          not null
#  not_taking_medication :boolean          not null
#  notes                 :text             default(""), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  patient_session_id    :bigint           not null
#  performed_by_user_id  :bigint           not null
#  programme_id          :bigint           not null
#  session_date_id       :bigint           not null
#
# Indexes
#
#  index_pre_screenings_on_patient_session_id    (patient_session_id)
#  index_pre_screenings_on_performed_by_user_id  (performed_by_user_id)
#  index_pre_screenings_on_programme_id          (programme_id)
#  index_pre_screenings_on_session_date_id       (session_date_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_session_id => patient_sessions.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (session_date_id => session_dates.id)
#
class PreScreening < ApplicationRecord
  audited associated_with: :patient_session

  belongs_to :patient_session
  belongs_to :session_date
  belongs_to :programme
  belongs_to :performed_by,
             class_name: "User",
             foreign_key: :performed_by_user_id

  has_one :patient, through: :patient_session

  encrypts :notes

  validates :knows_vaccination,
            :not_already_had,
            :feeling_well,
            :no_allergies,
            :not_taking_medication,
            :not_pregnant,
            inclusion: {
              in: [true, false]
            }

  def allows_vaccination?
    knows_vaccination && not_already_had && no_allergies &&
      (
        !PreScreening.ask_not_taking_medication?(programme:) ||
          not_taking_medication
      ) && (!PreScreening.ask_not_pregnant?(programme:) || not_pregnant)
  end

  def self.ask_not_taking_medication?(programme:)
    programme.doubles?
  end

  def self.ask_not_pregnant?(programme:)
    programme.hpv? || programme.td_ipv?
  end
end
