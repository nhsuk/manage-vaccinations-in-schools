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
describe CareplusExportVaccinationRecord do
  subject(:record) { build(:careplus_export_vaccination_record) }

  describe "associations" do
    it { should belong_to(:careplus_export) }
    it { should belong_to(:vaccination_record) }
  end

  describe "validations" do
    it { should be_valid }

    it do
      expect(record).to validate_inclusion_of(:change_type).in_array(
        %w[created updated]
      )
    end
  end
end
