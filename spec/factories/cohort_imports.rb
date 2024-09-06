# frozen_string_literal: true

# == Schema Information
#
# Table name: cohort_imports
#
#  id                           :bigint           not null, primary key
#  csv_data                     :text
#  csv_filename                 :text
#  csv_removed_at               :datetime
#  exact_duplicate_record_count :integer
#  new_record_count             :integer
#  processed_at                 :datetime
#  recorded_at                  :datetime
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  uploaded_by_user_id          :bigint           not null
#
# Indexes
#
#  index_cohort_imports_on_uploaded_by_user_id  (uploaded_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (uploaded_by_user_id => users.id)
#
FactoryBot.define do
  factory :cohort_import do
    uploaded_by

    csv_data { "my,csv\n" }
    csv_filename { Faker::File.file_name(ext: "csv") }

    trait :csv_removed do
      csv_data { nil }
      csv_removed_at { Time.zone.now }
    end
  end
end
