# frozen_string_literal: true

# == Schema Information
#
# Table name: class_imports
#
#  id                           :bigint           not null, primary key
#  changed_record_count         :integer
#  csv_data                     :text
#  csv_filename                 :text
#  csv_removed_at               :datetime
#  exact_duplicate_record_count :integer
#  new_record_count             :integer
#  processed_at                 :datetime
#  recorded_at                  :datetime
#  serialized_errors            :json
#  status                       :integer          default("pending_import"), not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  session_id                   :bigint           not null
#  team_id                      :bigint           not null
#  uploaded_by_user_id          :bigint           not null
#
# Indexes
#
#  index_class_imports_on_session_id           (session_id)
#  index_class_imports_on_team_id              (team_id)
#  index_class_imports_on_uploaded_by_user_id  (uploaded_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (session_id => sessions.id)
#  fk_rails_...  (team_id => teams.id)
#  fk_rails_...  (uploaded_by_user_id => users.id)
#
FactoryBot.define do
  factory :class_import do
    session
    team { session.team }
    uploaded_by

    csv_data { "my,csv\n" }
    csv_filename { Faker::File.file_name(ext: "csv") }

    trait :csv_removed do
      csv_data { nil }
      csv_removed_at { Time.zone.now }
    end

    trait :pending do
      status { :pending_import }
    end

    trait :invalid do
      serialized_errors { { "errors" => ["Error 1", "Error 2"] } }
      status { :rows_are_invalid }
    end

    trait :processed do
      processed_at { Time.zone.now }
      status { :processed }

      changed_record_count { 0 }
      exact_duplicate_record_count { 0 }
      new_record_count { 0 }
    end

    trait :recorded do
      processed
      recorded_at { Time.zone.now }
      status { :recorded }
    end
  end
end
