# == Schema Information
#
# Table name: vaccination_records
#
#  id                 :bigint           not null, primary key
#  administered       :boolean
#  administered_at    :date
#  site               :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  patient_session_id :bigint           not null
#
# Indexes
#
#  index_vaccination_records_on_patient_session_id  (patient_session_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_session_id => patient_sessions.id)
#
class VaccinationRecord < ApplicationRecord
  belongs_to :patient_session

  enum :site, %i[left_arm right_arm other]

  validates :administered, inclusion: [true, false]
  validates :site,
            presence: true,
            inclusion: {
              in: sites.keys
            },
            if: -> { administered }

  def self.site_options
    sites.map { |k, id| OpenStruct.new(id:, name: k.humanize) }
  end
end
