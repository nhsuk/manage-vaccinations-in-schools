# frozen_string_literal: true

# == Schema Information
#
# Table name: pds_search_results
#
#  id          :bigint           not null, primary key
#  import_type :string
#  nhs_number  :string
#  result      :integer          not null
#  step        :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  import_id   :bigint
#  patient_id  :bigint           not null
#
# Indexes
#
#  index_pds_search_results_on_import      (import_type,import_id)
#  index_pds_search_results_on_patient_id  (patient_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#
describe PDSSearchResult, type: :model do
  subject(:pds_search_result) { build(:pds_search_result) }

  describe "associations" do
    it { should belong_to(:patient) }
    it { should belong_to(:import).optional }
  end
end
