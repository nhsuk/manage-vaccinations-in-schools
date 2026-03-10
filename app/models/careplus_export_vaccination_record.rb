# frozen_string_literal: true

# == Schema Information
#
# Table name: careplus_export_vaccination_records
#
#  change_type           :integer          not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  careplus_export_id    :bigint           not null, primary key
#  vaccination_record_id :bigint           not null, primary key
#
# Indexes
#
#  idx_on_careplus_export_id_8ce4ed1ff0     (careplus_export_id)
#  idx_on_vaccination_record_id_d4c93aefb7  (vaccination_record_id)
#
# Foreign Keys
#
#  fk_rails_...  (careplus_export_id => careplus_exports.id) ON DELETE => cascade
#  fk_rails_...  (vaccination_record_id => vaccination_records.id)
#
class CareplusExportVaccinationRecord < ApplicationRecord
  self.primary_key = %i[careplus_export_id vaccination_record_id]

  belongs_to :careplus_export
  belongs_to :vaccination_record

  enum :change_type, { created: 0, updated: 1 }, validate: true
end
