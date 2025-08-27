# frozen_string_literal: true

class RemoveIndexPDSSearchResultsOnPatientImportStep < ActiveRecord::Migration[
  8.0
]
  def change
    remove_index :pds_search_results,
                 name: "index_pds_search_results_on_patient_import_step",
                 column: %i[patient_id import_type import_id step],
                 unique: true
  end
end
