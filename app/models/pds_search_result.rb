# frozen_string_literal: true

class PDSSearchResult < ApplicationRecord
  belongs_to :patient
  belongs_to :class_import, optional: true
  belongs_to :cohort_import, optional: true

  enum :step,
       {
         no_fuzzy_with_history: 0,
         no_fuzzy_without_history: 1,
         no_fuzzy_with_wildcard_postcode: 2,
         no_fuzzy_with_wildcard_given_name: 3,
         no_fuzzy_with_wildcard_family_name: 4,
         fuzzy_without_history: 5,
         fuzzy_with_history: 6
       },
       validate: true

  enum :result,
       { no_matches: 0, one_match: 1, too_many_matches: 2 },
       validate: true

  def import
    class_import || cohort_import
  end
end
