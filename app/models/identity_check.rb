# frozen_string_literal: true

# == Schema Information
#
# Table name: identity_checks
#
#  id                              :bigint           not null, primary key
#  confirmed_by_other_name         :string           default(""), not null
#  confirmed_by_other_relationship :string           default(""), not null
#  confirmed_by_patient            :boolean          not null
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  vaccination_record_id           :bigint           not null
#
# Indexes
#
#  index_identity_checks_on_vaccination_record_id  (vaccination_record_id)
#
# Foreign Keys
#
#  fk_rails_...  (vaccination_record_id => vaccination_records.id) ON DELETE => cascade
#
class IdentityCheck < ApplicationRecord
  audited

  belongs_to :vaccination_record

  scope :confirmed_by_patient, -> { where(confirmed_by_patient: true) }

  scope :confirmed_by_other, -> { where(confirmed_by_patient: false) }

  validates :confirmed_by_other_name,
            :confirmed_by_other_relationship,
            presence: {
              if: :confirmed_by_other?
            },
            absence: {
              if: :confirmed_by_patient?
            }

  def confirmed_by_other? = !confirmed_by_patient
end
