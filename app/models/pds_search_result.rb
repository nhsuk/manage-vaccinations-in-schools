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
#  index_pds_search_results_on_import               (import_type,import_id)
#  index_pds_search_results_on_patient_id           (patient_id)
#  index_pds_search_results_on_patient_import_step  (patient_id,import_type,import_id,step) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#
class PDSSearchResult < ApplicationRecord
  belongs_to :patient
  belongs_to :import, polymorphic: true, optional: true

  enum :step,
       {
         no_fuzzy_with_history: 0,
         no_fuzzy_with_history_daily: 1,
         no_fuzzy_without_history: 2,
         no_fuzzy_with_wildcard_postcode: 3,
         no_fuzzy_with_wildcard_given_name: 4,
         no_fuzzy_with_wildcard_family_name: 5,
         fuzzy_without_history: 6,
         fuzzy_with_history: 7
       },
       validate: true

  enum :result,
       { no_matches: 0, one_match: 1, too_many_matches: 2 },
       validate: true
end
