# == Schema Information
#
# Table name: vaccination_records
#
#  id                 :bigint           not null, primary key
#  administered       :boolean
#  reason             :integer
#  recorded_at        :datetime
#  site               :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  batch_id           :bigint
#  patient_session_id :bigint           not null
#
# Indexes
#
#  index_vaccination_records_on_batch_id            (batch_id)
#  index_vaccination_records_on_patient_session_id  (patient_session_id)
#
# Foreign Keys
#
#  fk_rails_...  (batch_id => batches.id)
#  fk_rails_...  (patient_session_id => patient_sessions.id)
#
class VaccinationRecord < ApplicationRecord
  belongs_to :patient_session
  belongs_to :batch, optional: true
  has_one :vaccine, through: :batch

  enum :site, %i[left_arm right_arm other]
  enum :reason,
       %i[
         refused
         not_well
         contraindications
         already_had
         absent_from_school
         absent_from_session
       ]

  validates :administered, inclusion: [true, false]
  validates :batch_id,
            presence: true,
            on: :edit_batch,
            if: -> { administered }
  validates :site,
            presence: true,
            inclusion: {
              in: sites.keys,
            },
            if: -> { administered }

  def vaccine_name
    patient_session.session.campaign.vaccines.first.type
  end

  def location_name
    patient_session.session.location&.name
  end
end
